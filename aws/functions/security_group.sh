#!/bin/bash

# constants
SECURITY_GROUP_PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources
source "$SECURITY_GROUP_PREFIX/../../general/functions/constants.sh"
source "$SECURITY_GROUP_PREFIX/../../general/functions/general.sh"

# functions
create_sg() {
    local name="$1"
    local desc="$2"
    local vpc_id="$3"

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_sg' is called with no security group name" >&2
        return 1
    fi

    if [[ -z "$desc" ]]; then
        echo "invalid function call: 'create_sg' is called with no security group description" >&2
        return 1
    fi

    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'create_sg' is called with no vpc id" >&2
        return 1
    fi

    local id
    id=$(aws ec2 create-security-group \
        --group-name "${name}" \
        --description "${desc}" \
        --vpc-id "${vpc_id}" \
        --query 'GroupId' \
        --output text) || return "$?"

    echo "$id"
}

allow_incoming_traffic_on_port_ipv4_for_sg() {
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr="$4"
    local description="$5"

    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv4_for_sg' is called with sg_id" >&2
        return 1
    fi

    if [[ -z "$protocol" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv4_for_sg' is called with protocol" >&2
        return 1
    fi

    if [[ -z "$port" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv4_for_sg' is called with port" >&2
        return 1
    fi

    if [[ -z "$cidr" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv4_for_sg' is called with cidr" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv4_for_sg' is called with description" >&2
        return 1
    fi

    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --ip-permissions \
        "IpProtocol=$protocol,FromPort=$port,ToPort=$port,IpRanges=[{CidrIp=$cidr,Description='$description'}]" >"$DEV_NULL" || return "$?"
}

allow_incoming_traffic_on_port_ipv6_for_sg() {
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr="$4"
    local description="$5"

    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv6_for_sg' is called with sg_id" >&2
        return 1
    fi

    if [[ -z "$protocol" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv6_for_sg' is called with protocol" >&2
        return 1
    fi

    if [[ -z "$port" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv6_for_sg' is called with port" >&2
        return 1
    fi

    if [[ -z "$cidr" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv6_for_sg' is called with cidr" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_ipv6_for_sg' is called with description" >&2
        return 1
    fi

    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --ip-permissions \
        "IpProtocol=$protocol,FromPort=$port,ToPort=$port,Ipv6Ranges=[{CidrIpv6=$cidr,Description='$description'}]" >"$DEV_NULL" || return "$?"
}

allow_incoming_traffic_on_port_from_another_sg() {
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local source_sg="$4"

    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_from_another_sg' is called with no security group id" >&2
        return 1
    fi

    if [[ -z "$protocol" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_from_another_sg' is called with no protocol" >&2
        return 1
    fi

    if [[ -z "$port" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_from_another_sg' is called with no port" >&2
        return 1
    fi

    if [[ -z "$source_sg" ]]; then
        echo "invalid function call: 'allow_incoming_traffic_on_port_from_another_sg' is called with no other security group id" >&2
        return 1
    fi

    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --protocol "$protocol" \
        --port "$port" \
        --source-group "$source_sg" >"$DEV_NULL" || return "$?"
}

allow_traffic_within_sg() {
    local sg_id="$1"

    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_traffic_within_sg' is called with no security group id" >&2
        return 1
    fi

    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --protocol -1 \
        --source-group "$sg_id" >"$DEV_NULL" || return "$?"
}

allow_http_for_sg() {
    local sg_id="$1"
    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_http_for_sg' is called with no argument" >&2
        return 1
    fi

    allow_incoming_traffic_on_port_ipv4_for_sg "$sg_id" "tcp" 80 "0.0.0.0/0" "Allow HTTP from all ipv4 addresses" || return "$?"
    allow_incoming_traffic_on_port_ipv6_for_sg "$sg_id" "tcp" 80 "::/0" "Allow HTTP from all ipv6 addresses" || return "$?"
}

allow_https_for_sg() {
    local sg_id="$1"
    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_http_for_sg' is called with no argument" >&2
        return 1
    fi

    allow_incoming_traffic_on_port_ipv4_for_sg "$sg_id" "tcp" 443 "0.0.0.0/0" "Allow HTTPs from all ipv4 addresses" || return "$?"
    allow_incoming_traffic_on_port_ipv6_for_sg "$sg_id" "tcp" 443 "::/0" "Allow HTTPs from all ipv6 addresses" || return "$?"
}

allow_ssh_from_all_ips_for_sg() {
    local sg_id="$1"
    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_http_for_sg' is called with no argument" >&2
        return 1
    fi

    allow_incoming_traffic_on_port_ipv4_for_sg "$sg_id" "tcp" 22 "0.0.0.0/0" "Allow ssh from all ipv4 addresses" || return "$?"
    allow_incoming_traffic_on_port_ipv6_for_sg "$sg_id" "tcp" 22 "::/0" "Allow ssh from all ipv6 addresses" || return "$?"
}

disallow_incoming_traffic_on_port_ipv4_for_sg() {
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr="$4"
    if [[ -z "$sg_id" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no sg_id"
    fi

    if [[ -z "$protocol" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no protocol"
    fi

    if [[ -z "$port" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no port"
    fi

    if [[ -z "$cidr" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no cidr"
    fi

    aws ec2 revoke-security-group-ingress \
        --group-id "$sg_id" \
        --protocol "$protocol" \
        --port "$port" \
        --cidr "$cidr" >"$DEV_NULL" || return "$?"
}

disallow_incoming_traffic_on_port_ipv6_for_sg() {
    local sg_id="$1"
    local protocol="$2"
    local port="$3"
    local cidr="$4"
    if [[ -z "$sg_id" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no sg_id"
    fi

    if [[ -z "$protocol" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no protocol"
    fi

    if [[ -z "$port" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no port"
    fi

    if [[ -z "$cidr" ]]; then
        die "invalid function call: 'disallow_incoming_traffic_on_port_ipv4_for_sg' is called with no cidr"
    fi

    aws ec2 revoke-security-group-ingress \
        --group-id "$sg_id" \
        --ip-permissions "IpProtocol=$protocol,FromPort=$port,ToPort=$port,Ipv6Ranges=[{CidrIpv6=$cidr}]" >"$DEV_NULL" || return "$?"
}

disallow_ssh_from_all_ips_for_sg() {
    local sg_id="$1"
    if [[ -z "$sg_id" ]]; then
        die "invalid function call: 'disallow_ssh_from_all_ips_for_sg' is called with no argument"
    fi

    disallow_incoming_traffic_on_port_ipv4_for_sg "$sg_id" "tcp" 22 "0.0.0.0/0" || return "$?"
    disallow_incoming_traffic_on_port_ipv6_for_sg "$sg_id" "tcp" 22 "::/0" || return "$?"
}

allow_all_traffic_from_another_sg() {
    local sg_id="$1"
    local source_sg="$2"
    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_all_traffic_from_another_sg' is called with no security group id" >&2
        return 1
    fi

    if [[ -z "$source_sg" ]]; then
        echo "invalid function call: 'allow_all_traffic_from_another_sg' is called with no other security group id" >&2
        return 1
    fi

    allow_incoming_traffic_on_port_from_another_sg "$sg_id" "-1" "all" "$source_sg"
}

allow_ssh_from_my_ip_for_sg() {
    local sg_id="$1"
    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'allow_ssh_from_my_ip_for_sg' is called with no security group id" >&2
        return 1
    fi

    allow_incoming_traffic_on_port_ipv4_for_sg "$sg_id" "tcp" "22" "$(get_my_ip)/32" "Allow SSH from my ip"
}

delete_sg() {
    local sg_id="$1"
    if [[ -z "$sg_id" ]]; then
        echo "invalid function call: 'delete_sg' is called with no security group id" >&2
        return 1
    fi

    aws ec2 delete-security-group --group-id "$sg_id" || return "$?"
}