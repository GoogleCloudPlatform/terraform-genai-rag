# terraform-genai-retrieval-augmented-generation

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deletion\_protection | Whether or not to protect GCS resources from deletion when solution is modified or changed. | `string` | `true` | no |
| enable\_apis | Whether or not to enable underlying apis in this solution. . | `string` | `true` | no |
| force\_destroy | Whether or not to protect BigQuery resources from deletion when solution is modified or changed. | `string` | `false` | no |
| labels | A map of labels to apply to contained resources. | `map(string)` | <pre>{<br>  "genai-rag": true<br>}</pre> | no |
| project\_id | Google Cloud Project ID | `string` | n/a | yes |
| public\_data\_bucket | Public Data bucket for access | `string` | `"data-analytics-demos"` | no |
| region | Google Cloud Region | `string` | `"us-central1"` | no |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
