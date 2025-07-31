#!/bin/bash

# constants
EC2_PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources
source "$EC2_PREFIX/../../general/functions/ssh.sh"
source "$EC2_PREFIX/../../general/functions/constants.sh"

# functions
create_ec2_instance() {
    local ami_id="$1"
    local instance_type="$2"
    local key_name="$3"
    local secg_id="$4"
    local name="$5"
    local count="${6:-1}"
    local init_script_path="$7"
    local subnet_id="$8"
    local instance_profile_name="$9"

    if [[ -z "$ami_id" ]]; then
        echo "invalid function call: 'create_ec2_instance' was called with no ami_id" >&2
        return 1
    fi

    if [[ -z "$instance_type" ]]; then
        echo "invalid function call: 'create_ec2_instance' was called with no instance_type" >&2
        return 1
    fi

    if [[ -z "$key_name" ]]; then
        echo "invalid function call: 'create_ec2_instance' was called with no key_name" >&2
        return 1
    fi

    if [[ -z "$secg_id" ]]; then
        echo "invalid function call: 'create_ec2_instance' was called with no secg_id" >&2
        return 1
    fi

    local cmd="aws ec2 run-instances \
        --image-id $ami_id \
        --count $count \
        --instance-type $instance_type \
        --key-name $key_name \
        --security-group-ids $secg_id \
        --query 'Instances[0].InstanceId' \
        --output text \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$name}]' \
                             'ResourceType=volume,Tags=[{Key=Name,Value=disk-$name}]'"

    if [[ -n "$subnet_id" ]]; then
        cmd+=" --subnet-id $subnet_id"
    fi

    if [[ -n "$init_script_path" ]]; then
        cmd+=" --user-data file://$init_script_path"
    fi

    if [[ -n "$instance_profile_name" ]]; then
        cmd+=" --iam-instance-profile Name=$instance_profile_name"
    fi

    local output
    output=$(eval "$cmd") || return "$?"

    echo "$output"
}

get_instance_private_ip() {
    local instance_id="$1"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'get_instance_private_ip' is called with no instance_id" >&2
        return 1
    fi

    local private_ip
    private_ip=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text) || return "$?"

    echo "$private_ip"
}

get_instance_public_ip() {
    local instance_id="$1"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'get_instance_public_ip' is called with no instance_id" >&2
        return 1
    fi

    local public_ip
    public_ip=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text | tr -d '[:space:]') || return "$?"

    echo "$public_ip" | tr -d '[:space:]'
}

wait_till_ec2_instance_is_running() {
    local instance_id="$1"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'wait_ec2_instance_is_running' is called with no instance_id" >&2
        return 1
    fi

    aws ec2 wait instance-running --instance-ids "$instance_id" || return "$?"
}

ssh_add_ec2_host_to_known_hosts() {
    local instance_id="$1"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'ssh_add_ec2_host_to_known_hosts' is called with no instance_id" >&2
        return 1
    fi

    local public_ip
    public_ip=$(get_instance_public_ip "$instance_id") || return "$?"
    ssh_add_host_to_known_hosts "$public_ip" || return "$?"
}

terminate_ec2_instances() {
    if [[ $# -eq 0 ]]; then
        echo "invalid function call: 'terminate_ec2_instances' is called with no instance ids" >&2
        return 1
    fi

    aws ec2 terminate-instances --instance-ids "$@" >"$DEV_NULL" || return "$?"
}

get_ec2_instance_sg_ids() {
    local instance_id="$1"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'get_ec2_instance_sg_ids' is called with no instance_id" >&2
        return 1
    fi

    local sg_ids
    sg_ids=$(aws ec2 describe-instances \
        --instance-ids "$instance_id" \
        --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' \
        --output text) || return "$?"
    echo "$sg_ids"
}

wait_till_ec2_instance_is_terminated() {
    local instance_id="$1"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'wait_till_ec2_instance_is_terminated' is called with no instance id" >&2
        return 1
    fi

    aws ec2 wait instance-terminated --instance-ids "$instance_id" || return "$?"
}
