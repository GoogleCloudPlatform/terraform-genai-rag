/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_service_account" "runsa" {
  project      = module.project-services.project_id
  account_id   = "genai-rag-run-sa"
  display_name = "Service Account for Cloud Run"

}

resource "google_project_iam_member" "allrun" {
  for_each = toset([
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
    "roles.run.invoker",
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.runsa.email}"
}

resource "google_cloud_run_v2_service" "retrieval_service" {
  name     = "retrieval-service"
  location = var.region
  project  = module.project-services.project_id

  template {
    service_account = google_service_account.runsa.email
    labels          = var.labels

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = var.retrieval_container
      env {
        name  = "APP_HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "APP_PORT"
        value = "8080"
      }
      env {
        name  = "DB_KIND"
        value = "cloudsql-postgres"
      }
      env {
        name  = "DB_PROJECT"
        value = module.project-services.project_id
      }
      env {
        name  = "DB_REGION"
        value = var.region
      }
      env {
        name  = "DB_INSTANCE"
        value = google_sql_database_instance.main.name
      }
      env {
        name  = "DB_NAME"
        value = "assistantdemo"
      }
      env {
        name  = "DB_USER"
        value = "postgres"
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.main.id
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    google_sql_user.main,
    google_sql_database.database
  ]
}


resource "google_cloud_run_v2_service" "frontend_service" {
  name     = "frontend-service"
  location = var.region
  project  = module.project-services.project_id

  template {
    service_account = google_service_account.runsa.email
    labels          = var.labels

    containers {
      image = var.frontend_container
      env {
        name  = "SERVICE_URL"
        value = google_cloud_run_v2_service.retrieval_service.uri
      }
      env {
        name  = "SERVICE_ACCOUNT_EMAIL"
        value = google_service_account.runsa.email
      }
    }
  }

  # depends_on = [
  #   google_sql_user.main,
  #   google_sql_database.database
  # ]
}

resource "google_cloud_run_service_iam_member" "noauth_frontend" {
  location = google_cloud_run_v2_service.frontend_service.location
  project  = google_cloud_run_v2_service.frontend_service.project
  service  = google_cloud_run_v2_service.frontend_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}