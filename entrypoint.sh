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

changes_present=$INPUT_TF_ACTION_OUTPUT_CHANGES_PRESENT
if [ -z "${changes_present}" ]; then
    echo "ERROR # 1 : Missing TF_ACTION_OUTPUT_CHANGES_PRESENT environment variable"
    exit 1
fi

if [ "${changes_present}" = "true" ]; then
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
    echo "\nThe 'fastly_service_config_url' and 'fastly_service_version_info' output parameters have been set and are ready to use in later jobs!"
elif [ "${changes_present}" = "false" ]; then
    echo "No action is required because no Terraform changes are present!"
else
    echo "ERROR # 1 : The TF_ACTION_OUTPUT_CHANGES_PRESENT environment variable must be a boolean ('true' or 'false')"
    exit 1
fi

