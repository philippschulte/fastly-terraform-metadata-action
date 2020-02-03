FROM alpine:3

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh"]

LABEL maintainer="Fastly"
LABEL repository="http://github.com/fastly/fastly-terraform-metadata-action"
LABEL homepage="https://www.fastly.com/"

LABEL "com.github.actions.name"="Fastly Terraform Metadata Action"
LABEL "com.github.actions.description"="Provides metadata for a Fastly service configuration managed by Terraform"
LABEL "com.github.actions.icon"="clock"
LABEL "com.github.actions.color"="red"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
