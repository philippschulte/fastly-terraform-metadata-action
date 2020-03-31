# Fastly Terraform Metadata Action

GitHub Action for retrieving metadata of a Fastly service configuration which is managed by Terraform.

## Prerequisites

This GitHub action only works in conjunction with the [Terraform GitHub Actions](https://www.terraform.io/docs/github-actions/index.html). The action requires the [tf_actions_plan_has_changes](https://github.com/hashicorp/terraform-github-actions#outputs) and the [tf_actions_output](https://github.com/hashicorp/terraform-github-actions#outputs) outputs as inputs. The Terraform service configuration must include output declarations for the [id](https://www.terraform.io/docs/providers/fastly/r/service_v1.html#id), [active_version](https://www.terraform.io/docs/providers/fastly/r/service_v1.html#active_version), and [cloned_version](https://www.terraform.io/docs/providers/fastly/r/service_v1.html#cloned_version).

A detailed example on how to chain the actions together as well as the necessary declarations in the Terraform service configuration can be found in the [Example](#example) section.

## Inputs

| Name                     | Default        | Description                                                                                                               |
|--------------------------|----------------|---------------------------------------------------------------------------------------------------------------------------|
| tf_plan_has_changes      |                | **Required**. The output of the Terraform GitHub plan action                                                              |
| tf_output_json_string    |                | **Required**. The output of the Terraform GitHub output action                                                            |
| tf_output_service_id     | service_id     | **Optional**. The name of the Terraform output variable representing the "id" of the Fastly service                       |
| tf_output_active_version | active_version | **Optional**. The name of the Terraform output variable representing the currently "active_version" of the Fastly service |
| tf_output_cloned_version | cloned_version | **Optional**. The name of the Terraform output variable representing the latest "cloned_version" of the Fastly service    |

## Outputs

| Name                        | Description                                                         |
|-----------------------------|---------------------------------------------------------------------|
| fastly_service_config_url   | The URL to the latest Fastly service version modified by Terraform  |
| fastly_service_version_info | Whether Terraform created, cloned, or activated the service version |
| fastly_service_id           | The alphanumeric string identifying a Fastly service                |
| fastly_active_version       | The number of the version activated by Terraform                    |
| fastly_cloned_version       | The number of the version cloned by Terraform                       |

## Example

**example.tf**
```hcl
provider "fastly" {
  ...
}

resource "fastly_service_v1" "example" {
  ...
}

output "active_version" {
  value = fastly_service_v1.example.active_version
}

output "cloned_version" {
  value = fastly_service_v1.example.cloned_version
}

output "service_id" {
  value = fastly_service_v1.example.id
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
      TF_VERSION: latest
      TF_VAR_FASTLY_EXAMPLE_API_KEY: ${{ secrets.TF_VAR_FASTLY_EXAMPLE_API_KEY }}
    steps:
      - name: Checkout
        uses: actions/checkout@master
      - name: Terraform Init
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: ${{ env.TF_VERSION }}
          tf_actions_subcommand: init
          tf_actions_comment: false
      - name: Terraform Import
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: ${{ env.TF_VERSION }}
          tf_actions_subcommand: import
          tf_actions_comment: false
          args: fastly_service_v1.example <service_id>
      - name: Terraform Plan
        id: plan
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: ${{ env.TF_VERSION }}
          tf_actions_subcommand: plan
          tf_actions_comment: false
          args: -out=example.plan
      - name: Terraform Apply
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: ${{ env.TF_VERSION }}
          tf_actions_subcommand: apply
          tf_actions_comment: false
          args: example.plan
      - name: Terraform Output
        id: output
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: ${{ env.TF_VERSION }}
          tf_actions_subcommand: output
      - name: Fastly Service Metadata
        id: metadata
        uses: fastly/fastly-terraform-metadata-action@master
        with:
          tf_plan_has_changes: ${{ steps.plan.outputs.tf_actions_plan_has_changes }}
          tf_output_json_string: ${{ steps.output.outputs.tf_actions_output }}
      - name: Slack Notification
        if: steps.plan.outputs.changes-present == 'true'
        uses: rtCamp/action-slack-notify@master
        env:
          SLACK_CHANNEL: example
          SLACK_COLOR: #3278BD
          SLACK_ICON: https://github.com/rtCamp.png?size=48
          SLACK_MESSAGE: ${{ steps.metadata.outputs.fastly_service_config_url }}
          SLACK_TITLE: ${{ steps.metadata.outputs.fastly_service_version_info }}
          SLACK_USERNAME: Terraform
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

## Metadata

- Engineer: Philipp Schulte
