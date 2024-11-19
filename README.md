# terraform-genai-retrieval-augmented-generation

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| database\_type | Cloud SQL MySQL, Cloud SQL PostgreSQL, AlloyDB, or Cloud Spanner | `string` | `"postgresql"` | no |
| deletion\_protection | Whether or not to protect Cloud SQL resources from deletion when solution is modified or changed. | `string` | `false` | no |
| enable\_apis | Whether or not to enable underlying apis in this solution. . | `string` | `true` | no |
| frontend\_container | The public Artifact Registry URI for the frontend container | `string` | `"us-docker.pkg.dev/google-samples/containers/jss/rag-frontend-service:v0.0.2"` | no |
| labels | A map of labels to apply to contained resources. | `map(string)` | <pre>{<br>  "genai-rag": true<br>}</pre> | no |
| project\_id | Google Cloud Project ID | `string` | n/a | yes |
| region | Google Cloud Region | `string` | `"us-central1"` | no |
| retrieval\_container | The public Artifact Registry URI for the retrieval container | `string` | `"us-docker.pkg.dev/google-samples/containers/jss/rag-retrieval-service:v0.0.3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| deployment\_ip\_address | Web URL link |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
