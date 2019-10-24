FROM hashicorp/terraform:0.12.12

LABEL maintainer="Fastly"
LABEL repository="http://github.com/philippschulte/fastly-terraform-metadata-action"
LABEL homepage="https://www.fastly.com/"

LABEL "com.github.actions.name"="Fastly Terraform Metadata Action"
LABEL "com.github.actions.description"="Provides metadata for a Fastly service configuration managed by Terraform"
LABEL "com.github.actions.icon"="clock"
LABEL "com.github.actions.color"="red"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

