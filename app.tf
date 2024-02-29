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

# resource "google_project_iam_member" "allrun" {
#   for_each = toset(var.run_roles_list)
#   project  = data.google_project.project.number
#   role     = each.key
#   member   = "serviceAccount:${google_service_account.runsa.email}"
# }
