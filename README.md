# Fastly Terraform Metadata Action

GitHub Action for retrieving metadata for a Fastly service configuration which is managed by Terraform.

## Prerequisites

This GitHub Action only works in conjunction with [Terraform GitHub Actions](https://www.terraform.io/docs/github-actions/index.html). The Action needs the `changes_present` output variable of the [Terraform Plan Action](https://www.terraform.io/docs/github-actions/actions/plan.html) as an input in order to determine if Terraform performed changes to the Fastly service configuration. The Terraform definition for the [fastly_service_v1](https://www.terraform.io/docs/providers/fastly/r/service_v1.html) resource must include declarations for the `id`, `active_version`, and `cloned_version` output values. A detailed example of how to use the Actions together and the necessary declarations in the Terraform definition can be found in the [Example](#example-usage) section.

## Inputs

| Name                             	| Default           	| Description                                                                                                 	            |
|----------------------------------	|-------------------	|-------------------------------------------------------------------------------------------------------------------------- |
| tf_action_output_changes_present 	|                   	| **Required**. Whether the resulting Terraform plan succeeded with empty diff or non-empty diff                            |
| tf_version                       	|                   	| **Required**. The Terraform version to install and execute. If set to `latest`, the latest stable version will be used.   |
| tf_output_service_id             	| service_id        	| **Optional**. The name of the Terraform output variable representing the "id" of the Fastly service                       |
| tf_output_active_version         	| active_version    	| **Optional**. The name of the Terraform output variable representing the currently "active_version" of the Fastly service |
| tf_output_cloned_version         	| cloned_version    	| **Optional**. The name of the Terraform output variable representing the latest "cloned_version" of the Fastly service    |
| tf_state_path                    	| terraform.tfstate 	| **Optional**. Path to the Terraform state file                                                                            |

## Outputs

| Name                        	| Description                                                         	                    |
|-----------------------------	|------------------------------------------------------------------------------------------ |
| fastly_service_config_url   	| A URL linking to the latest Fastly service version modified by Terraform                  |
| fastly_service_version_info 	| Human-friendly description of whether Terraform created, cloned, or activated the version |
| fastly_service_id           	| The alphanumeric string identifying a Fastly service                	                    |
| fastly_active_version       	| The number of the currently active version of the Fastly service     	                    |
| fastly_cloned_version       	| The number of the latest modified version by Terraform              	                    |

## Example

**example.tf**
```hcl
provider "fastly" {
  ...
}

resource "fastly_service_v1" "demo" {
  ...
}

output "active_version" {
  value = fastly_service_v1.demo.active_version
}

output "cloned_version" {
  value = fastly_service_v1.demo.cloned_version
}

output "service_id" {
  value = fastly_service_v1.demo.id
}
```

**.github/workflows/example.yml**
```yml
name: Action Example
on:
  push:
    branches:
      - master
jobs:
  example:
    name: Example
    runs-on: ubuntu-latest
    env:
      TF_VAR_FASTLY_EXAMPLE_API_KEY: ${{ secrets.TF_VAR_FASTLY_EXAMPLE_API_KEY }}
    steps:
      - name: Checkout
        uses: actions/checkout@v1
      - name: Terraform Init
        uses: hashicorp/terraform-github-actions@0.7.1
        with:
          tf_actions_version: 0.12.19
          tf_actions_subcommand: init
          tf_actions_comment: false
      - name: Terraform Plan
        id: plan
        uses: hashicorp/terraform-github-actions@0.7.1
        with:
          tf_actions_version: 0.12.19
          tf_actions_subcommand: plan
          tf_actions_comment: false
          args: -out=example.plan
      - name: Terraform Apply
        uses: hashicorp/terraform-github-actions@0.7.1
        with:
          tf_actions_version: 0.12.19
          tf_actions_subcommand: apply
          tf_actions_comment: false
          args: example.plan
      - name: Fastly Service Metadata
        id: metadata
        uses: fastly/fastly-terraform-metadata-action@0.2.0
        with:
          tf_version: 0.12.19
          tf_plan_has_changes: ${{ steps.plan.outputs.tf_actions_plan_has_changes }}
      - name: Slack Notification
        if: steps.plan.outputs.changes-present == 'true'
        uses: rtCamp/action-slack-notify@master
        env:
          SLACK_CHANNEL: 'example'
          SLACK_COLOR: '#3278BD'
          SLACK_ICON: https://github.com/rtCamp.png?size=48
          SLACK_MESSAGE: ${{ steps.metadata.outputs.fastly_service_config_url }}
          SLACK_TITLE: ${{ steps.metadata.outputs.fastly_service_version_info }}
          SLACK_USERNAME: Terraform
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

## Metadata

- Team: Product Engineering
- Slack: #team-app-eng
