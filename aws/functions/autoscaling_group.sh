#!/bin/bash

# constants
PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources


# functions
create_autoscaling_group_with_elb_check() {
    local asg_name="$1"
    local launch_temp_name="$2"
    
    # shellcheck disable=SC2016
    local launch_temp_version="${3:-'$Latest'}"
    local min_size="${4:-1}"
    local max_size="${5:-4}"
    local desired_capacity="${6:-2}"
    local subnets_str="$7"
    local tg_arn="$8"
    local health_check_grace_period="${9:-300}"

    if [[ -z "$asg_name" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no asg_name" >&2
        return 1
    fi

    if [[ -z "$launch_temp_name" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no launch_temp_name" >&2
        return 1
    fi

    if [[ -z "$launch_temp_version" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no launch_temp_version" >&2
        return 1
    fi

    if [[ -z "$min_size" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no min_size" >&2
        return 1
    fi

    if [[ -z "$max_size" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no max_size" >&2
        return 1
    fi

    if [[ -z "$desired_capacity" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no desired_capacity" >&2
        return 1
    fi

    if [[ -z "$subnets_str" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no subnets_str" >&2
        return 1
    fi

    if [[ -z "$tg_arn" ]]; then
        echo "invalid function call: 'create_autoscaling_group_with_elb_check' is called with no tg_arn" >&2
        return 1
    fi

    echo "$subnets_str"
    local subnets_arr
    read -ra subnets_arr <<< "$subnets_str"
    subnets_str=$(printf '%s,' "${subnets_arr[@]}")
    echo "$subnets_str"
    subnets_str=${subnets_str%,}
    echo "$subnets_str"
    
    aws autoscaling create-auto-scaling-group \
        --auto-scaling-group-name "$asg_name" \
        --launch-template "LaunchTemplateName=$launch_temp_name,Version=$launch_temp_version" \
        --min-size "$min_size" \
        --max-size "$max_size" \
        --desired-capacity "$desired_capacity" \
        --vpc-zone-identifier "$subnets_str" \
        --target-group-arns "$tg_arn" \
        --health-check-type ELB \
        --health-check-grace-period "$health_check_grace_period" || return "$?"
}

add_autoscaling_policy_for_asg() {
    local asg_name="$1"
    local policy_name="$2"
    local policy_type="$3"
    local tracking_conf="$4"

    if [[ -z "$asg_name" ]]; then
        echo "invalid function call: 'add_autoscaling_policy_for_asg' is called with no asg_name" >&2
        return 1
    fi

    if [[ -z "$policy_name" ]]; then
        echo "invalid function call: 'add_autoscaling_policy_for_asg' is called with no policy_name" >&2
        return 1
    fi

    if [[ -z "$policy_type" ]]; then
        echo "invalid function call: 'add_autoscaling_policy_for_asg' is called with no policy_type" >&2
        return 1
    fi

    if [[ -z "$tracking_conf" ]]; then
        echo "invalid function call: 'add_autoscaling_policy_for_asg' is called with no tracking_conf" >&2
        return 1
    fi

    local policy_arn
    policy_arn=$(aws autoscaling put-scaling-policy \
        --auto-scaling-group-name "$asg_name" \
        --policy-name "$policy_name" \
        --policy-type "$policy_type" \
        --target-tracking-configuration "$tracking_conf" \
        --query 'PolicyARN' \
        --output text) || return "$?"

    echo "$policy_arn"
}