#!/bin/bash

# sources
source ./load_balancer.sh
source ./ec2.sh

# functions
create_elastic_beanstalk_app() {
    local app_name="$1"
    local app_description="$2"

    if [[ -z "$app_name" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app' is called with no app_name" >&2
        return 1
    fi

    if [[ -z "$app_description" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app' is called with no app_description" >&2
        return 1
    fi

    local result
    result=$(aws elasticbeanstalk create-application --application-name "$app_name" --description "$app_description" --query "Application.ApplicationName" --output text) || return "$?"
    echo "$result"
}

create_elastic_beanstalk_app_version() {
    local app_name="$1"
    local version_label="$2"
    local source_bucket="$3"
    local build_path="$4"
    local description="$5"

    if [[ -z "$app_name" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app_version' is called with no app_name" >&2
        return 1
    fi

    if [[ -z "$version_label" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app_version' is called with no version_label" >&2
        return 1
    fi

    if [[ -z "$source_bucket" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app_version' is called with no source_bucket" >&2
        return 1
    fi

    if [[ -z "$build_path" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app_version' is called with no build_path" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_app_version' is called with no description" >&2
        return 1
    fi

    local result
    result=$(aws elasticbeanstalk create-application-version \
        --application-name "$app_name" \
        --version-label "$version_label" \
        --source-bundle S3Bucket="$source_bucket",S3Key="$build_path" \
        --description "$description" \
        --query "ApplicationVersion.ApplicationName" \
        --output text) || return "$?"
    echo "$result"
}

create_elastic_beanstalk_env() {
    local app_name="$1"
    local env_name="$2"
    local platform_arn="$3"
    local tier_name="$4"
    local tier_type="$5"
    local version_label="$6"
    local options_file_relevant_path="$7"

    if [[ -z "$app_name" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no app_name" >&2
        return 1
    fi

    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no env_name" >&2
        return 1
    fi

    if [[ -z "$platform_arn" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no platform_arn" >&2
        return 1
    fi

    if [[ -z "$tier_name" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no tier" >&2
        return 1
    fi

    if [[ -z "$tier_type" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no tier_type" >&2
        return 1
    fi

    if [[ -z "$version_label" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no version_label" >&2
        return 1
    fi

    if [[ -z "$options_file_relevant_path" ]]; then
        echo "invalid function call: 'create_elastic_beanstalk_env' is called with no options_file_relevant_path" >&2
        return 1
    fi

    local cname
    cname=$(aws elasticbeanstalk create-environment \
        --application-name "$app_name" \
        --environment-name "$env_name" \
        --platform-arn "$platform_arn" \
        --tier "{\"Name\":\"$tier_name\", \"Type\":\"$tier_type\"}" \
        --option-settings file://"$options_file_relevant_path" \
        --version-label "$version_label" \
        --query "CNAME" \
        --output text) || return "$?"
    echo "$cname"
}

get_elastic_beanstalk_env_alb_arn() {
    local env_name="$1"
    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'get_elastic_beanstalk_env_alb_arn' is called with no env_name" >&2
        return 1
    fi

    local alb_arn
    alb_arn=$(aws elasticbeanstalk describe-environment-resources \
        --environment-name "$env_name" \
        --query "EnvironmentResources.LoadBalancers[0].Name" \
        --output text) || return "$?"
    echo "$alb_arn"
}

get_elastic_beanstalk_env_alb_sg_ids() {
    local env_name="$1"
    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'get_elastic_beanstalk_env_alb_sg_ids' is called with no env_name" >&2
        return 1
    fi

    local alb_arn
    alb_arn=$(get_elastic_beanstalk_env_alb_arn "$env_name") || return "$?"

    local alb_sgs
    alb_sgs=$(get_alb_sg_ids "$alb_arn") || return "$?"
    echo "$alb_sgs"
}

get_elastic_beanstalk_env_ec2_instance_ids() {
    local env_name="$1"
    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'get_elastic_beanstalk_env_instance_ids' is called with no env_name" >&2
        return 1
    fi

    local instance_ids
    instance_ids=$(aws elasticbeanstalk describe-environment-resources \
        --environment-name "$env_name" \
        --query "EnvironmentResources.Instances[*].Id" \
        --output text) || return "$?"
    echo "$instance_ids"
}

get_elastic_beanstalk_env_single_ec2_instance_id() {
    local env_name="$1"
    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'get_elastic_beanstalk_env_single_instance_id' is called with no env_name" >&2
        return 1
    fi

    local instance_ids
    instance_ids=$(get_elastic_beanstalk_env_ec2_instance_ids "$env_name") || return "$?"
    local single_instance_id
    single_instance_id=$(awk '{print $1}' <<<"$instance_ids")
    echo "$single_instance_id"
}

get_elastic_beanstalk_env_ec2_instance_sg_ids() {
    local env_name="$1"
    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'get_elastic_beanstalk_env_ec2_instance_sg_ids' is called with no env_name" >&2
        return 1
    fi

    local instance_id
    instance_id=$(get_elastic_beanstalk_env_single_ec2_instance_id "$env_name") || return "$?"
    local sg_ids
    sg_ids=$(get_ec2_instance_sg_ids "$instance_id") || return "$?"
    echo "$sg_ids"
}

wait_elastic_beanstalk_env() {
    local env_name="$1"
    if [[ -z "$env_name" ]]; then
        echo "invalid function call: 'wait_elastic_beanstalk_env' is called with no env_name" >&2
        return 1
    fi
    while true; do
        aws elasticbeanstalk wait environment-updated --environment-name "$env_name" && return 0
        sleep 1
    done
}