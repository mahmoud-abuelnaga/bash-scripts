#!/bin/bash

# constants
TARGET_GROUP_PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources
source "$TARGET_GROUP_PREFIX/../../general/functions/constants.sh"

# functions
create_target_group() {
    local tg_name="$1"
    local forwarding_protocol="$2"
    local traffic_port="$3"
    local vpc_id="$4"
    local target_type="${5:-instance}"
    local health_check_protocol="${6:-HTTP}"
    local health_check_port="${7:-$traffic_port}"
    local health_check_path="${8:-/}"
    local health_check_interval_seconds="${9:-30}"
    local health_check_timeout_seconds="${10:-6}"
    local healthy_threshold_count="${11:-5}"
    local unhealthy_threshold_count="${12:-2}"

    if [[ -z "$tg_name" ]]; then
        echo "invalid function call: 'create_target_group' is called with no tg_name" >&2
        return 1
    fi

    if [[ -z "$forwarding_protocol" ]]; then
        echo "invalid function call: 'create_target_group' is called with no forwarding_protocol" >&2
        return 1
    fi

    if [[ -z "$traffic_port" ]]; then
        echo "invalid function call: 'create_target_group' is called with no traffic_port" >&2
        return 1
    fi

    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'create_target_group' is called with no vpc_id" >&2
        return 1
    fi

    if [[ -z "$target_type" ]]; then
        echo "invalid function call: 'create_target_group' is called with no target_type" >&2
        return 1
    fi

    if [[ -z "$health_check_protocol" ]]; then
        echo "invalid function call: 'create_target_group' is called with no health_check_protocol" >&2
        return 1
    fi

    if [[ -z "$health_check_port" ]]; then
        echo "invalid function call: 'create_target_group' is called with no health_check_port" >&2
        return 1
    fi

    if [[ -z "$health_check_path" ]]; then
        echo "invalid function call: 'create_target_group' is called with no health_check_path" >&2
        return 1
    fi

    if [[ -z "$health_check_interval_seconds" ]]; then
        echo "invalid function call: 'create_target_group' is called with no health_check_interval_seconds" >&2
        return 1
    fi

    if [[ -z "$health_check_timeout_seconds" ]]; then
        echo "invalid function call: 'create_target_group' is called with no health_check_timeout_seconds" >&2
        return 1
    fi

    if [[ -z "$healthy_threshold_count" ]]; then
        echo "invalid function call: 'create_target_group' is called with no healthy_threshold_count" >&2
        return 1
    fi

    if [[ -z "$unhealthy_threshold_count" ]]; then
        echo "invalid function call: 'create_target_group' is called with no unhealthy_threshold_count" >&2
        return 1
    fi

    local tg_arn
    tg_arn=$(aws elbv2 create-target-group \
        --name "$tg_name" \
        --protocol "$forwarding_protocol" \
        --port "$traffic_port" \
        --vpc-id "$vpc_id" \
        --target-type "$target_type" \
        --health-check-protocol "$health_check_protocol" \
        --health-check-port "$health_check_port" \
        --health-check-path "$health_check_path" \
        --health-check-interval-seconds "$health_check_interval_seconds" \
        --health-check-timeout-seconds "$health_check_timeout_seconds" \
        --healthy-threshold-count "$healthy_threshold_count" \
        --unhealthy-threshold-count "$unhealthy_threshold_count" \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text) || return "$?"

    echo "$tg_arn"
}

enable_tg_lb_stickness() {
    local tg_arn="$1"
    local stickness_duration="$2"

    if [[ -z "$tg_arn" ]]; then
        echo "invalid function call: 'enable_tg_lb_stickness' is called with no tg_arn" >&2
        return 1
    fi

    if [[ -z "$stickness_duration" ]]; then
        echo "invalid function call: 'enable_tg_lb_stickness' is called with no stickness_duration" >&2
        return 1
    fi

    aws elbv2 modify-target-group-attributes \
        --target-group-arn "$tg_arn" \
        --attributes Key=stickiness.enabled,Value=true Key=stickiness.type,Value=lb_cookie Key=stickiness.lb_cookie.duration_seconds,Value="$stickness_duration" > "$DEV_NULL" || return "$?"
}