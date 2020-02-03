#!/bin/sh

check_exit_status()
{
    status=$1
    message=$2
    if [ "${status}" -ne "0" ]; then
        echo "ERROR # ${status} : ${message}"
        exit ${status}
    fi
}

set_action_output()
{
    name=$1
    value=$2
    if [ -z "${name}" ] || [ -z "${value}" ]; then
        return 1
    fi
    echo "::set-output name=${name}::${value}"
}

get_service_config_link()
{
    id=$1
    version=$2
    if [ -z "${id}" ] || [ -z "${version}" ]; then
        return 1
    fi
    echo "https://manage.fastly.com/configure/services/${id}/versions/${version}"
}

install_terraform()
{
    if [ "${terraform_version}" == "latest" ]; then
        echo "Checking the latest version of Terraform"
        terraform_version=$(curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].version' | grep -v '[-].*' | sort -rV | head -n 1)
        if [ -z "${terraform_version}" ]; then
            return 1
        fi
    fi

    echo "Downloading Terraform v${terraform_version}"
    url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
    curl -s -S -L -o /tmp/terraform_${terraform_version} ${url}
    if [ "${?}" -ne 0 ]; then
        return 2
    fi
    echo "Successfully downloaded Terraform v${terraform_version}"

    echo "Unzipping Terraform v${terraform_version}"
    unzip -d /usr/local/bin /tmp/terraform_${terraform_version} &> /dev/null
    if [ "${?}" -ne 0 ]; then
        return 3
    fi
    echo "Successfully unzipped Terraform v${terraform_version}"
}

changes_present=$INPUT_TF_PLAN_HAS_CHANGES
if [ -z "${changes_present}" ]; then
    echo "ERROR # 1 : Input tf_plan_has_changes cannot be empty"
    exit 1
fi

terraform_version=$INPUT_TF_VERSION
if [ -z "${terraform_version}" ]; then
    echo "ERROR # 1 : Input tf_version cannot be empty"
    exit 1
fi

if [ "${changes_present}" = "true" ]; then
    install_terraform
    INSTALL_TERRAFORM_RETURN_CODE=$?
    if [ "$INSTALL_TERRAFORM_RETURN_CODE" -eq "1" ]; then
        echo "ERROR # 1 : Failed to fetch the latest version"
        exit 1
    elif [ "$INSTALL_TERRAFORM_RETURN_CODE" -eq "2" ]; then
        echo "ERROR # 2 : Failed to download Terraform v${terraform_version}"
        exit 2
    elif [ "$INSTALL_TERRAFORM_RETURN_CODE" -eq "3" ]; then
        echo "ERROR # 3 : Failed to unzip Terraform v${terraform_version}"
        exit 3
    fi
  
    service_id=$( sh -c "TF_IN_AUTOMATION=true terraform output -no-color -state=${INPUT_TF_STATE_PATH} ${INPUT_TF_OUTPUT_SERVICE_ID}" 2> /dev/null )
    check_exit_status $? "Failed to extract the value of the '${INPUT_TF_OUTPUT_SERVICE_ID}' output variable from the Terraform state file"
    active_version=$( sh -c "TF_IN_AUTOMATION=true terraform output -no-color -state=${INPUT_TF_STATE_PATH} ${INPUT_TF_OUTPUT_ACTIVE_VERSION}" 2> /dev/null )
    check_exit_status $? "Failed to extract the value of the '${INPUT_TF_OUTPUT_ACTIVE_VERSION}' output variable from the Terraform state file"
    cloned_version=$( sh -c "TF_IN_AUTOMATION=true terraform output -no-color -state=${INPUT_TF_STATE_PATH} ${INPUT_TF_OUTPUT_CLONED_VERSION}" 2> /dev/null )
    check_exit_status $? "Failed to extract the value of the '${INPUT_TF_OUTPUT_CLONED_VERSION}' output variable from the Terraform state file"

    if [ $active_version -lt $cloned_version ]; then
        link=$( get_service_config_link $service_id $cloned_version )
        check_exit_status $? "Failed to get the link to the latest cloned version configuration, service_id: '${service_id}', version '${cloned_version}'"
        info="Terraform created version ${cloned_version} of service ${service_id} which is waiting to be reviewed and activated."
    elif [ $active_version -eq $cloned_version ]; then
        link=$( get_service_config_link $service_id $active_version )
        check_exit_status $? "Failed to get the link to the active version configuration, service_id: '${service_id}', version '${active_version}'"
        info="Terraform created and activated version ${active_version} of service ${service_id}."
    fi

    set_action_output "fastly_service_config_url" "${link}"
    check_exit_status $? "Failed to set 'fastly_service_config_url' output parameter"
    set_action_output "fastly_service_version_info" "${info}"
    check_exit_status $? "Failed to set 'fastly_service_version_info' output parameter"
    set_action_output "fastly_service_id" "${service_id}"
    check_exit_status $? "Failed to set 'fastly_service_id' output parameter"
    set_action_output "fastly_active_version" "${active_version}"
    check_exit_status $? "Failed to set 'fastly_active_version' output parameter"
    set_action_output "fastly_cloned_version" "${cloned_version}"
    check_exit_status $? "Failed to set 'fastly_cloned_version' output parameter"
    echo "\nThe 'fastly_service_config_url', 'fastly_service_version_info', 'fastly_service_id', 'fastly_active_version', and 'fastly_cloned_version' output parameters have been set and are ready to use in later steps!"
elif [ "${changes_present}" = "false" ]; then
    echo "No action is required because no Terraform changes are present!"
else
    echo "ERROR # 1 : Input tf_plan_has_changes must be a boolean ('true' or 'false')"
    exit 1
fi
