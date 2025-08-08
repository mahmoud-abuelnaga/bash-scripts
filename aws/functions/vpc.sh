#!/bin/bash

# constants


# sources


# functions
describe_vpc_subnets() {
    local vpc_id="$1"
    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'describe_vpc_subnets' is called with no vpc_id" >&2
        return 1
    fi

    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query "Subnets[*].SubnetId" --output text
}

get_ig_id_of_vpc() {
    local vpc_id="$1"
    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'get_ig_id_of_vpc' is called with no vpc_id" >&2
        return 1
    fi

    local ig_id
    ig_id=$(aws ec2 describe-internet-gateways \
                --query "InternetGateways[?Attachments[?VpcId==\`$vpc_id\`]].InternetGatewayId" \
                --output text) || return "$?"

    echo "$ig_id"
}

get_subnets_explicitly_associated_with_ig() {
    local ig_id="$1"
    if [[ -z "$ig_id" ]]; then
        echo "invalid function call: 'get_explicitly_associated_subnets_to_ig' is called with no ig_id" >&2
        return 1
    fi

    local subnets
    subnets=$(aws ec2 describe-route-tables \
                --filters Name=route.gateway-id,Values="$ig_id" \
                --query "RouteTables[].Associations[?SubnetId!=\`null\`].SubnetId" \
                --output text) || return "$?"

    echo "$subnets"
}

get_subnets_implicitly_associated_with_ig() {
    local ig_id="$1"
    if [[ -z "$ig_id" ]]; then
        echo "invalid function call: 'get_implicitly_associated_subnets_to_ig' is called with no ig_id" >&2
        return 1
    fi


    local all_subnets
    all_subnets=$(describe_vpc_subnets "$vpc_id") || return "$?"

    local explicitly_associated_subnets
    explicitly_associated_subnets=$(get_subnets_explicitly_associated_with_ig "$ig_id") || return "$?"

    local implicitly_associated_subnets
    implicitly_associated_subnets=$(comm -23 <(echo "$all_subnets" | tr ' ' '\n' | sort) <(echo "$explicitly_associated_subnets" | tr ' ' '\n' | sort)) || return "$?"

    echo "$implicitly_associated_subnets"
}

get_subnets_associated_with_ig() {
    local ig_id="$1"
    if [[ -z "$ig_id" ]]; then
        echo "invalid function call: 'get_subnets_associated_with_ig' is called with no ig_id" >&2
        return 1
    fi

    local explicitly_associated_subnets
    explicitly_associated_subnets=$(get_subnets_explicitly_associated_with_ig "$ig_id") || return "$?"

    local implicitly_associated_subnets
    implicitly_associated_subnets=$(get_subnets_implicitly_associated_with_ig "$ig_id") || return "$?"

    echo "$explicitly_associated_subnets" "$implicitly_associated_subnets"
}

get_public_subnets_of_vpc() {
    local vpc_id="$1"
    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'get_public_subnets_of_vpc' is called with no vpc_id" >&2
        return 1
    fi

    local ig_id
    ig_id=$(get_ig_id_of_vpc "$vpc_id") || return "$?"

    local subnets
    subnets=$(get_subnets_associated_with_ig "$ig_id") || return "$?"

    echo "$subnets"
}
