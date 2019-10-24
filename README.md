# Fastly Terraform Metadata Action

GitHub Action for retrieving metadata for a Fastly service configuration which is managed by Terraform.

## Prerequisites

This GitHub Action only works in conjunction with [Terraform GitHub Actions](https://www.terraform.io/docs/github-actions/index.html). The Action needs the `changes_present` output variable of the [Terraform Plan Action](https://www.terraform.io/docs/github-actions/actions/plan.html) as an input in order to determine if Terraform performed changes to the Fastly service configuration. The Terraform definition for the [fastly_service_v1](https://www.terraform.io/docs/providers/fastly/r/service_v1.html) resource must include declarations for the `id`, `active_version`, and `cloned_version` output values. A detailed example of how to use the Actions together and the necessary declarations in the Terraform definition can be found in the [Example](#example-usage) section.

## Inputs

| Name                             	| Default           	| Description                                                                                                 	            |
|----------------------------------	|-------------------	|-------------------------------------------------------------------------------------------------------------------------- |
| tf_action_output_changes_present 	|                   	| **Required**. Whether the resulting Terraform plan succeeded with empty diff or non-empty diff                            |
| tf_output_service_id             	| service_id        	| **Optional**. The name of the Terraform output variable representing the "id" of the Fastly service                       |
| tf_output_active_version         	| active_version    	| **Optional**. The name of the Terraform output variable representing the currently "active_version" of the Fastly service |
| tf_output_cloned_version         	| cloned_version    	| **Optional**. The name of the Terraform output variable representing the latest "cloned_version" of the Fastly service    |
| tf_state_path                    	| terraform.tfstate 	| **Optional**. Path to the Terraform state file                                                                            |

## Outputs

| Name                        	| Description                                                         	|
|-----------------------------	|---------------------------------------------------------------------	|
| fastly_service_config_url   	| The link to the latest Fastly service version modified by Terraform 	|
| fastly_service_version_info 	| Whether Terraform created, cloned, or activated the version         	|

## Example

**main.tf**
```hcl
provider "fastly" {
    ...
}

resource "fastly_service_v1" "demo" {
    ...
}

output "active" {
    value = fastly_service_v1.demo.active_version
}

output "cloned" {
    value = fastly_service_v1.demo.cloned_version
}

output "id" {
    value = fastly_service_v1.demo.id
}
```

**.github/workflows/main.yml**
```hcl
```