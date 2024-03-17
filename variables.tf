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

# --------------------------------------------------
# VARIABLES
# Set these before applying the configuration
# --------------------------------------------------

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

# tflint-ignore: terraform_unused_declarations
variable "region" {
  type        = string
  description = "Google Cloud Region"
  default     = "us-central1"
}

# tflint-ignore: terraform_unused_declarations
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

# tflint-ignore: terraform_unused_declarations
variable "force_destroy" {
  type        = string
  description = "Whether or not to protect BigQuery resources from deletion when solution is modified or changed."
  default     = false
}

# tflint-ignore: terraform_unused_declarations
variable "deletion_protection" {
  type        = string
  description = "Whether or not to protect GCS resources from deletion when solution is modified or changed."
  default     = true
}

# tflint-ignore: terraform_unused_declarations
variable "public_data_bucket" {
  type        = string
  description = "Public Data bucket for access"
  default     = "data-analytics-demos"
}
