#!/bin/bash

# constants
AMI_PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources
source "$AMI_PREFIX/ec2.sh"
source "$AMI_PREFIX/security_group.sh"
source "$AMI_PREFIX/key.sh"

# functions
create_image_from_ec2_instance() {
    local instance_id="$1"
    local name="$2"
    local description="$3"
    if [[ -z "$instance_id" ]]; then
        echo "invalid function call: 'create_image_from_ec2_instance' is called with no instance_id" >&2
        return 1
    fi

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_image_from_ec2_instance' is called with no name" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_image_from_ec2_instance' is called with no description" >&2
        return 1
    fi

    local image_id
    image_id=$(aws ec2 create-image \
        --instance-id "$instance_id" \
        --name "$name" \
        --description "$description" \
        --query 'ImageId' \
        --output text) || return "$?"

    echo "$image_id"
}

wait_till_image_is_available() {
    local image_id="$1"
    if [[ -z "$image_id" ]]; then
        echo "invalid function call: 'wait_till_image_is_available' is called with no image_id" >&2
        return 1
    fi

    aws ec2 wait image-available --image-ids "$image_id" || return "$?"
}

create_ami_with_live_script() {
    local ami_id="$1"
    local vpc_id="$2"
    local subnet_id="$3"
    local live_script_path="$4"
    local user="$5"
    local image_name="$6"
    local image_description="$7"
    local instance_profile_name="$8"
    local use_sudo="${9:-1}"

    if [[ -z "$ami_id" ]]; then
        echo "invalid function call: 'create_ami_with_live_script' is called with no ami_id" >&2
        return 1
    fi

    if [[ -z "$vpc_id" ]]; then
        echo "invalid function call: 'create_ami_with_live_script' is called with no vpc_id" >&2
        return 1
    fi

    if [[ -z "$subnet_id" ]]; then
        echo "invalid function call: 'create_ami_with_live_script' is called with no subnet_id" >&2
        return 1
    fi

    if [[ -z "$live_script_path" ]]; then
        echo "invalid function call: 'create_ami_with_live_script' is called with no live_script_path" >&2
        return 1
    fi

    if [[ -z "$user" ]]; then
        echo "invalid function call: 'create_ami_with_live_script' is called with no user" >&2
        return 1
    fi

    local sg_id
    sg_id=$(create_sg "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" "$vpc_id") || return "$?"
    allow_ssh_from_my_ip_for_sg "$sg_id" || return "$?"

    local key_name
    key_name=$(openssl rand -hex 32)
    create_key_pair "$key_name" || return "$?"

    local instance_id
    instance_id=$(create_ec2_instance "$ami_id" "t2.micro" "$key_name" "$sg_id" "$(openssl rand -hex 32)" "1" "" "$subnet_id" "$instance_profile_name") || return "$?"
    wait_till_ec2_instance_is_running "$instance_id" || return "$?"
    sleep 60

    local public_ip
    public_ip=$(get_instance_public_ip "$instance_id") || return "$?"
    ssh_add_host_to_known_hosts "$public_ip" || return "$?"

    if [[ "$use_sudo" -eq 1 ]]; then
        ssh -i "$key_name.pem" "$user@$public_ip" "sudo bash -s" <"$live_script_path" >&2 || return "$?"
    else
        ssh -i "$key_name.pem" "$user@$public_ip" "bash -s" <"$live_script_path" >&2 || return "$?"
    fi

    local image_id
    image_id=$(create_image_from_ec2_instance "$instance_id" "$image_name" "$image_description") || return "$?"
    wait_till_image_is_available "$image_id" || return "$?"
    echo "$image_id"

    terminate_ec2_instances "$instance_id" >&2 || return "$?"
    wait_till_ec2_instance_is_terminated "$instance_id" || return "$?"
    delete_sg "$sg_id" >&2 || return "$?"
    delete_key_pair "$key_name" >&2 || return "$?"
    rm -f "$key_name.pem"
}
