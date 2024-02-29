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


resource "google_compute_network" "main" {
  name                    = "genai-rag-private-network"
  auto_create_subnetworks = true
  project                 = module.project-services.project_id
}

resource "google_compute_global_address" "main" {
  name          = "genai-rag-vpc-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.name
  project       = module.project-services.project_id
}

resource "google_service_networking_connection" "main" {
  network                 = google_compute_network.main.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.main.name]

}

resource "google_vpc_access_connector" "main" {
  project        = module.project-services.project_id
  name           = "genai-rag-vpc-cx"
  ip_cidr_range  = "10.8.0.0/28"
  network        = google_compute_network.main.name
  region         = var.region
  max_throughput = 300
}

# Handle Database
resource "google_sql_database_instance" "main" {
  name             = "genai-rag-db-${random_id.id.hex}"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = module.project-services.project_id

  settings {
    tier                  = "db-g1-small"
    disk_autoresize       = true
    disk_autoresize_limit = 0
    disk_size             = 10
    disk_type             = "PD_SSD"
    user_labels           = var.labels
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${module.project-services.project_id}/global/networks/${google_compute_network.main.name}"
    }
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }
  deletion_protection = false
}

# Grant the Run Service Account SQL Access
resource "google_sql_user" "main" {
  project         = module.project-services.project_id
  name            = "${google_service_account.runsa.account_id}@${module.project-services.project_id}.iam"
  type            = "CLOUD_IAM_SERVICE_ACCOUNT"
  instance        = google_sql_database_instance.main.name
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "database" {
  project         = var.project_id
  name            = "genai"
  instance        = google_sql_database_instance.main.name
  deletion_policy = "ABANDON"
}
