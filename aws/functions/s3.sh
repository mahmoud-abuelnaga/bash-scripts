#!/bin/bash

# constants
PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources


# functions
create_s3_bucket() {
    local bucket_name="$1"
    local bucket_region="$2"

    if [[ -z "$bucket_name" ]]; then
        echo "invalid function call: 'create_s3_bucket' is called with no bucket name" >&2
        return 1
    fi

    if [[ -z "$bucket_region" ]]; then
        echo "invalid function call: 'create_s3_bucket' is called with no bucket region" >&2
        return 1
    fi

    local location
    location=$(aws s3api create-bucket --bucket "$bucket_name" --region "$bucket_region" --query "Location" --output text) || return "$?"
    echo "$location"
}