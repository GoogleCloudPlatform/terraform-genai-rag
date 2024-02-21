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

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "14.2.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "artifactregistry.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "sql.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com",
  ]

  activate_api_identities = [
    {
      api = "workflows.googleapis.com"
      roles = [
        "roles/workflows.viewer"
      ]
    }
  ]
}

resource "random_id" "id" {
  byte_length = 4
}

# Set up the provisioning storage bucket
resource "google_storage_bucket" "raw_bucket" {
  name                        = "gcp-genai-rag-provisioning-${random_id.id.hex}"
  project                     = module.project-services.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  public_access_prevention = "enforced" # need to validate if this is a hard requirement
}

resource "google_storage_bucket_object" "airport" {
  name   = "airport_dataset.csv"
  source = "/data/airport_dataset.csv"
  bucket = google_storage_bucket.raw_bucket.name
}

resource "google_storage_bucket_object" "amenity" {
  name   = "amenity_dataset.csv"
  source = "/data/amenity_dataset.csv"
  bucket = google_storage_bucket.raw_bucket.name
}

resource "google_storage_bucket_object" "flights" {
  name   = "flights_dataset.csv"
  source = "/data/flights_dataset.csv"
  bucket = google_storage_bucket.raw_bucket.name
}
