#!/bin/bash

# constants
PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources

# functions
create_dns_route_53_private_hosted_zone() {
    local name="$1"
    local region="$2"
    local vpc_id="$3"
    local idempotency_token="$4"
    local comment="$5"

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_dns_route_53_private_hosted_zone' is called with no name" >&2
        return 1
    fi

    if [[ -z "$region" ]]; then
        echo "invalid function call: 'create_dns_route_53_private_hosted_zone' is called with no region" >&2
        return 1
    fi

    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'create_dns_route_53_private_hosted_zone' is called with no vpc_id" >&2
        return 1
    fi

    if [[ -z "$idempotency_token" ]]; then
        echo "invalid function call: 'create_dns_route_53_private_hosted_zone' is called with no idempotency_token" >&2
        return 1
    fi

    if [[ -z "$comment" ]]; then
        echo "invalid function call: 'create_dns_route_53_private_hosted_zone' is called with no comment" >&2
        return 1
    fi

    local output
    output=$(aws route53 create-hosted-zone \
        --name "$name" \
        --vpc VPCRegion="$region",VPCId="$vpc_id" \
        --caller-reference "$idempotency_token" \
        --hosted-zone-config Comment="$comment",PrivateZone=true \
        --query 'HostedZone.Id' \
        --output text) || return "$?"

    # remove the leading /hostedzone/ from the output
    local zone_id
    zone_id="${output#/hostedzone/}"

    echo "$zone_id"
}

create_change_record_set_string() {
    domain_name="$1"
    name_to_add="$2"
    private_ip="$3"

    if [[ -z "$domain_name" ]]; then
        echo "invalid function call: 'create_change_record_set_string' is called with no domain_name" >&2
        return 1
    fi

    if [[ -z "$name_to_add" ]]; then
        echo "invalid function call: 'create_change_record_set_string' is called with no name_to_add" >&2
        return 1
    fi

    if [[ -z "$private_ip" ]]; then
        echo "invalid function call: 'create_change_record_set_string' is called with no private_ip" >&2
        return 1
    fi

    cat <<EOF
{
    "Action": "CREATE",
    "ResourceRecordSet": {
        "Name": "$name_to_add.$domain_name",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
            { "Value": "$private_ip" }
        ]
    }
} 
EOF
}

update_hosted_zone_record_set() {
    local hosted_zone_id="$1"
    local changes_record_set="$2"

    if [[ -z "$hosted_zone_id" ]]; then
        echo "invalid function call: 'change_hosted_zone_record_set' is called with no hosted_zone_id" >&2
        return 1
    fi

    if [[ -z "$changes_record_set" ]]; then
        echo "invalid function call: 'change_hosted_zone_record_set' is called with no changes_record_set" >&2
        return 1
    fi

    local result
    result=$(aws route53 change-resource-record-sets \
        --hosted-zone-id "$hosted_zone_id" \
        --change-batch "$changes_record_set") || return "$?"

    # echo "$result"
}