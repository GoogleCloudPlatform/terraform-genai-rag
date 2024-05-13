/**
 * Copyright 2024 Google LLC
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


# Handle Database
resource "google_sql_database_instance" "main" {
  name             = "genai-rag-db-${random_id.id.hex}"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = module.project-services.project_id

  settings {
    tier                         = "db-custom-1-3840" # 1 CPU, 3.75GB Memory
    disk_autoresize              = true
    disk_autoresize_limit        = 0
    disk_size                    = 10
    disk_type                    = "PD_SSD"
    user_labels                  = var.labels
    enable_google_ml_integration = true
    ip_configuration {
      ipv4_enabled = true
    }
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
    database_flags {
      name  = "cloudsql.enable_google_ml_integration"
      value = "on"
    }
  }
  deletion_protection = var.deletion_protection

}

# # Create Database
resource "google_sql_database" "database" {
  project         = var.project_id
  name            = "assistantdemo"
  instance        = google_sql_database_instance.main.name
  deletion_policy = "ABANDON"
}

# # Create Cloud SQL User
resource "google_sql_user" "service" {
  name            = "retrieval-service"
  project         = module.project-services.project_id
  instance        = google_sql_database_instance.main.name
  type            = "BUILT_IN"
  password        = random_password.cloud_sql_password.result
  deletion_policy = "ABANDON"
}

# # Create SQL integration to vertex
resource "google_project_iam_member" "vertex_integration" {
  project = module.project-services.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_sql_database_instance.main.service_account_email_address}"
}
