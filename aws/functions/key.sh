#!/bin/bash

# constants
PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources

# functions
create_key_pair() {
    local key_name="$1"
    if [[ -z "$key_name" ]]; then
        echo "invalid function call: 'create_key_pair' was called with no key_name" >&2
        return 1
    fi

    aws ec2 create-key-pair \
        --key-name "$key_name" \
        --query 'KeyMaterial' \
        --output text >"$key_name".pem && chmod 400 "$key_name".pem
}

delete_key_pair() {
    local key_name="$1"
    if [[ -z "$key_name" ]]; then
        echo "invalid function call: 'delete_key_pair' is called with no key name" >&2
        return 1
    fi

    aws ec2 delete-key-pair --key-name "$key_name" || return "$?"
}