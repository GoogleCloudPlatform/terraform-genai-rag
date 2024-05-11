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

# --------------------------------------------------
# VARIABLES
# Set these before applying the configuration
# --------------------------------------------------

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "region" {
  type        = string
  description = "Google Cloud Region"
  default     = "us-central1"
}

variable "labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
  default     = { "genai-rag" = true }
}

variable "enable_apis" {
  type        = string
  description = "Whether or not to enable underlying apis in this solution. ."
  default     = true
}

variable "deletion_protection" {
  type        = string
  description = "Whether or not to protect Cloud SQL resources from deletion when solution is modified or changed."
  default     = false
}

variable "frontend_container" {
  type        = string
  description = "The public Artifact Registry URI for the frontend container"
  default     = "us-docker.pkg.dev/google-samples/containers/jss/rag-frontend-service:v0.0.1"
}

variable "retrieval_container" {
  type        = string
  description = "The public Artifact Registry URI for the retrieval container"
  default     = "us-docker.pkg.dev/google-samples/containers/jss/rag-retrieval-service:v0.0.2"
}
