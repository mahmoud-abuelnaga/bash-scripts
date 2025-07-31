#!/bin/bash

# constants


# sources


# functions
create_role() {
    local role_name="$1"
    local role_policy="$2"
    if [[ -z "$role_name" ]]; then
        echo "invalid function call: 'create_role' is called with no role name" >&2
        return 1
    fi

    if [[ -z "$role_policy" ]]; then
        echo "invalid function call: 'create_role' is called with no role policy" >&2
        return 1
    fi

    local role_arn
    role_arn=$(aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document "$role_policy" \
        --query 'Role.Arn' \
        --output text) || return "$?"
    echo "$role_arn"
}

create_policy() {
    local policy_name="$1"
    local policy_document="$2"
    if [[ -z "$policy_name" ]]; then
        echo "invalid function call: 'create_policy' is called with no policy name" >&2
        return 1
    fi

    if [[ -z "$policy_document" ]]; then
        echo "invalid function call: 'create_policy' is called with no policy document" >&2
        return 1
    fi

    local policy_arn
    policy_arn=$(aws iam create-policy \
        --policy-name "$policy_name" \
        --policy-document "$policy_document" \
        --query 'Policy.Arn' \
        --output text) || return "$?"
        
    echo "$policy_arn"
}

attach_policy_to_role() {
    local role_name="$1"
    local policy_arn="$2"
    if [[ -z "$role_name" ]]; then
        echo "invalid function call: 'attach_policy_to_role' is called with no role name" >&2
        return 1
    fi

    if [[ -z "$policy_arn" ]]; then
        echo "invalid function call: 'attach_policy_to_role' is called with no policy arn" >&2
        return 1
    fi

    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "$policy_arn" || return "$?"
}

create_instance_profile() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_instance_profile' is called with no name" >&2
        return 1
    fi

    local instance_profile_arn
    instance_profile_arn=$(aws iam create-instance-profile \
        --instance-profile-name "$name" \
        --query 'InstanceProfile.Arn' \
        --output text) || return "$?"
    
    echo "$instance_profile_arn"
}

add_role_to_instance_profile() {
    local instance_profile_name="$1"
    local role_name="$2"
    if [[ -z "$instance_profile_name" ]]; then
        echo "invalid function call: 'add_role_to_instance_profile' is called with no instance profile name" >&2
        return 1
    fi

    if [[ -z "$role_name" ]]; then
        echo "invalid function call: 'add_role_to_instance_profile' is called with no role name" >&2
        return 1
    fi

    aws iam add-role-to-instance-profile \
        --instance-profile-name "$instance_profile_name" \
        --role-name "$role_name" || return "$?"
}