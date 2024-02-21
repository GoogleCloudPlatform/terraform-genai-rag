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

resource "google_service_account" "workflows_sa" {
  project      = module.project-services.project_id
  account_id   = "workflows-sa-${random_id.id.hex}"
  display_name = "Workflows Service Account"
}

resource "google_project_iam_member" "workflows_sa_roles" {
  for_each = toset([
    "roles/workflows.admin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
  ])

  project = module.project-services.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.workflows_sa.email}"
}

# Workflow to set up project resources
# Note: google_storage_bucket.<bucket>.name omits the `gs://` prefix.
# You can use google_storage_bucket.<bucket>.url to include the prefix.
resource "google_workflows_workflow" "project_setup" {
  name            = "project-setup"
  project         = module.project-services.project_id
  region          = var.region
  description     = "Copies data and performs project setup"
  service_account = google_service_account.workflows_sa.email
  source_contents = templatefile("${path.module}/src/yaml/project-setup.yaml", {
    data_analyst_user         = google_service_account.data_analyst_user.email,
    marketing_user            = google_service_account.marketing_user.email,
    dataproc_service_account  = google_service_account.dataproc_service_account.email,
    provisioner_bucket        = google_storage_bucket.provisioning_bucket.name,
    warehouse_bucket          = google_storage_bucket.warehouse_bucket.name,
    temp_bucket               = google_storage_bucket.warehouse_bucket.name,
    dataplex_asset_tables_id  = "projects/${module.project-services.project_id}/locations/${var.region}/lakes/gcp-primary-lake/zones/gcp-primary-staging/assets/gcp-primary-tables"
    dataplex_asset_textocr_id = "projects/${module.project-services.project_id}/locations/${var.region}/lakes/gcp-primary-lake/zones/gcp-primary-raw/assets/gcp-primary-textocr"
    dataplex_asset_ga4_id     = "projects/${module.project-services.project_id}/locations/${var.region}/lakes/gcp-primary-lake/zones/gcp-primary-raw/assets/gcp-primary-ga4-obfuscated-sample-ecommerce"
  })

  depends_on = [
    google_project_iam_member.workflows_sa_roles,
    google_project_iam_member.dataproc_sa_roles
  ]

}

# execute workflows after all resources are created
# # get a token to execute the workflows
data "google_client_config" "current" {
}

# # execute the copy data workflow
data "http" "call_workflows_copy_data" {
  url    = "https://workflowexecutions.googleapis.com/v1/projects/${module.project-services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.copy_data.name}/executions"
  method = "POST"
  request_headers = {
    Accept = "application/json"
  Authorization = "Bearer ${data.google_client_config.current.access_token}" }
  depends_on = [
    google_storage_bucket.textocr_images_bucket,
    google_storage_bucket.ga4_images_bucket,
    google_storage_bucket.tables_bucket
  ]
}
