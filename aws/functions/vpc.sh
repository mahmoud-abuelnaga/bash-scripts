#!/bin/bash

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