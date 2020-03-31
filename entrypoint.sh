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
    echo "Setting '${name}' output parameter"
    if [ -z "${name}" ] || [ -z "${value}" ]; then
        return 1
    fi
    echo "::set-output name=${name}::${value}"
    echo "Successfully set '${name}' output parameter to '${value}'"
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

plan_has_changes=$INPUT_TF_PLAN_HAS_CHANGES
if [ -z "${plan_has_changes}" ]; then
    echo "ERROR # 1 : The tf_plan_has_changes input variable cannot be empty"
    exit 1
fi

if [ "${plan_has_changes}" = "true" ]; then
    service_id=$(echo $INPUT_TF_OUTPUT_JSON_STRING | jq -r -e .$INPUT_TF_OUTPUT_SERVICE_ID.value 2> /dev/null)
    check_exit_status $? "Failed to extract the value of the '${INPUT_TF_OUTPUT_SERVICE_ID}' output variable from the Terraform GitHub output action"
    active_version=$(echo $INPUT_TF_OUTPUT_JSON_STRING | jq -r -e .$INPUT_TF_OUTPUT_ACTIVE_VERSION.value 2> /dev/null)
    check_exit_status $? "Failed to extract the value of the '${INPUT_TF_OUTPUT_ACTIVE_VERSION}' output variable from the Terraform GitHub output action"
    cloned_version=$(echo $INPUT_TF_OUTPUT_JSON_STRING | jq -r -e .$INPUT_TF_OUTPUT_CLONED_VERSION.value 2> /dev/null)
    check_exit_status $? "Failed to extract the value of the '${INPUT_TF_OUTPUT_CLONED_VERSION}' output variable from the Terraform GitHub output action"

    if [ $active_version -lt $cloned_version ]; then
        link=$(get_service_config_link $service_id $cloned_version)
        check_exit_status $? "Failed to get the link to the latest cloned version configuration, service_id: '${service_id}', version '${cloned_version}'"
        info="Terraform created version ${cloned_version} of service ${service_id} which is waiting to be reviewed and activated."
    elif [ $active_version -eq $cloned_version ]; then
        link=$(get_service_config_link $service_id $active_version)
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
elif [ "${plan_has_changes}" = "false" ]; then
    echo "No action is required because no Terraform changes are present!"
else
    echo "ERROR # 1 : The tf_plan_has_changes input variable must be a boolean ('true' or 'false')"
    exit 1
fi
