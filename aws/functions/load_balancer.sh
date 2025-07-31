#!/bin/bash

# sources

# functions
create_load_balancer() {
    local name="$1"
    local scheme="$2"
    local type="$3"
    local ip_address_type="$4"
    local security_groups_str="$5"
    local subnets_str="$6"
    
    local security_groups
    read -ra security_groups <<< "$security_groups_str"

    local subnets
    read -ra subnets <<< "$subnets_str"

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_load_balancer' is called with no name" >&2
        return 1
    fi

    if [[ -z "$scheme" ]]; then
        echo "invalid function call: 'create_load_balancer' is called with no scheme" >&2
        return 1
    fi

    if [[ -z "$type" ]]; then
        echo "invalid function call: 'create_load_balancer' is called with no type" >&2
        return 1
    fi

    if [[ -z "$ip_address_type" ]]; then
        echo "invalid function call: 'create_load_balancer' is called with no ip_address_type" >&2
        return 1
    fi

    if [[ -z "$security_groups_str" ]]; then
        echo "invalid function call: 'create_load_balancer' is called with no security_groups" >&2
        return 1
    fi

    if [[ -z "$subnets_str" ]]; then
        echo "invalid function call: 'create_load_balancer' is called with no subnets" >&2
        return 1
    fi

    local lb_arn
    lb_arn=$(aws elbv2 create-load-balancer \
        --name "$name" \
        --scheme "$scheme" \
        --type "$type" \
        --ip-address-type "$ip_address_type" \
        --security-groups "${security_groups[@]}" \
        --subnets "${subnets[@]}" \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text) || return "$?"

    echo "$lb_arn"
}

create_load_balancer_listener() {
    local lb_arn="$1"
    local protocol="$2"
    local port="$3"
    local target_groupd_arn="$4"
    local action="${5:-forward}"
    local certificate_arn="$6"

    if [[ -z "$lb_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_listener' is called with no lb_arn" >&2
        return 1
    fi

    if [[ -z "$protocol" ]]; then
        echo "invalid function call: 'create_load_balancer_listener' is called with no protocol" >&2
        return 1
    fi

    if [[ -z "$port" ]]; then
        echo "invalid function call: 'create_load_balancer_listener' is called with no port" >&2
        return 1
    fi

    if [[ -z "$target_groupd_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_listener' is called with no target_groupd_arn" >&2
        return 1
    fi

    local cmd
    cmd="aws elbv2 create-listener \
            --load-balancer-arn $lb_arn \
            --protocol $protocol \
            --port $port \
            --default-actions Type=$action,TargetGroupArn=$target_groupd_arn \
            --query 'Listeners[0].ListenerArn' \
            --output text"

    if [[ -n "$certificate_arn" ]]; then
        cmd+=" --certificates CertificateArn=$certificate_arn"
    fi

    local listener_arn
    listener_arn=$(eval "$cmd") || return "$?"

    echo "$listener_arn"
}

create_load_balancer_http_listener() {
    local lb_arn="$1"
    local tg_arn="$2"
    if [[ -z "$lb_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_http_listener' is called with no lb_arn" >&2
        return 1
    fi

    if [[ -z "$tg_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_http_listener' is called with no tg_arn" >&2
        return 1
    fi

    local listener_arn
    listener_arn=$(create_load_balancer_listener "$lb_arn" "HTTP" "80" "$tg_arn") || return "$?"

    echo "$listener_arn"
}

create_load_balancer_https_listener() {
    local lb_arn="$1"
    local tg_arn="$2"
    local certificate_arn="$3"
    if [[ -z "$lb_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_https_listener' is called with no lb_arn" >&2
        return 1
    fi

    if [[ -z "$tg_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_https_listener' is called with no tg_arn" >&2
        return 1
    fi

    if [[ -z "$certificate_arn" ]]; then
        echo "invalid function call: 'create_load_balancer_https_listener' is called with no certificate_arn" >&2
        return 1
    fi

    local listener_arn
    listener_arn=$(create_load_balancer_listener "$lb_arn" "HTTPS" "443" "$tg_arn" "forward" "$certificate_arn") || return "$?"

    echo "$listener_arn"
}

get_alb_sg_ids() {
    local alb_arn="$1"
    if [[ -z "$alb_arn" ]]; then
        echo "invalid function call: 'get_alb_sg_ids' is called with no alb_arn" >&2
        return 1
    fi

    local alb_sgs
    alb_sgs=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns "$alb_arn" \
        --query "LoadBalancers[0].SecurityGroups" \
        --output text) || return "$?"
    echo "$alb_sgs"
}