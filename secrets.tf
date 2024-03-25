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

## Django Admin Password
resource "random_password" "cloud_sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "cloud_sql_password" {
  project   = module.project-services.project_id
  secret_id = "genai-cloud-sql-password-${random_id.id.hex}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = var.labels

  depends_on = [module.project-services]
}

resource "google_secret_manager_secret_iam_binding" "cloud_sql_password" {
  project   = module.project-services.project_id
  secret_id = google_secret_manager_secret.cloud_sql_password.id
  role      = "roles/secretmanager.secretAccessor"
  members   = ["serviceAccount:${google_service_account.runsa.email}"]
}

resource "google_secret_manager_secret_version" "cloud_sql_password" {
  secret      = google_secret_manager_secret.cloud_sql_password.id
  secret_data = random_password.cloud_sql_password.result
}
