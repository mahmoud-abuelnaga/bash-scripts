#!/bin/bash

# constants


# sources


# functions
create_broker() {
    local name="$1"
    local engine_type="$2"
    local engine_version="$3"
    local instance_type="$4"
    local deployment_mode="$5"
    local username="$6"
    local password="$7"
    local subnets_ids_str="$8"
    local security_groups_ids_str="$9"
    local public_access="${10:-false}"

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_broker' is called without a broker name" >&2
        return 1
    fi

    if [[ "$engine_type" != "RabbitMQ" && "$engine_type" != "ActiveMQ" ]]; then
        echo "invalid function call: 'create_broker' is called with an invalid engine type" >&2
        return 1
    fi

    if [[ -z "$instance_type" ]]; then
        echo "invalid function call: 'create_broker' is called without an instance type" >&2
        return 1
    fi

    if [[ $deployment_mode != "SINGLE_INSTANCE" && $deployment_mode != "CLUSTER_MULTI_AZ" ]]; then
        echo "invalid function call: 'create_broker' is called with an invalid deployment mode" >&2
        return 1
    fi

    if [[ -z "$username" ]]; then
        echo "invalid function call: 'create_broker' is called without a username" >&2
        return 1
    fi

    if [[ -z "$password" ]]; then
        echo "invalid function call: 'create_broker' is called without a password" >&2
        return 1
    fi

    if [[ -z "$subnets_ids_str" ]]; then
        echo "invalid function call: 'create_broker' is called without subnet ids" >&2
        return 1
    fi

    if [[ -z "$security_groups_ids_str" ]]; then
        echo "invalid function call: 'create_broker' is called without security group ids" >&2
        return 1
    fi

    local subnets_ids
    read -ra subnets_ids <<<"$subnets_ids_str"
    local security_groups_ids
    read -ra security_groups_ids <<<"$security_groups_ids_str"

    if [[ ${#subnets_ids[@]} -eq 0 ]]; then
        echo "invalid function call: 'create_broker' is called with no subnets" >&2
        return 1
    fi

    if [[ ${#security_groups_ids[@]} -eq 0 ]]; then
        echo "invalid function call: 'create_broker' is called with no security groups" >&2
        return 1
    fi

    local cmd
    cmd=$(
        cat <<EOF
        aws mq create-broker \
            --broker-name "$name" \
            --engine-type "$engine_type" \
            --engine-version "$engine_version" \
            --host-instance-type "$instance_type" \
            --deployment-mode "$deployment_mode" \
            --users Username="$username",Password="$password" \
            --security-groups "${security_groups_ids[@]}" \
            --query "BrokerId" \
            --output text
EOF
    )

    if [[ "$public_access" == "true" ]]; then
        cmd+=" --publicly-accessible"
    else
        cmd+=" --no-publicly-accessible"
    fi

    if [[ "$deployment_mode" == "SINGLE_INSTANCE" ]]; then
        cmd+=" --subnet-ids ${subnets_ids[0]}"
    else
        cmd+=" --subnet-ids ${subnets_ids[*]}"
    fi

    local broker_id
    broker_id=$(eval "$cmd") || return "$?"

    echo "$broker_id"
}

get_broker_endpoint() {
    local broker_id="$1"
    if [[ -z "$broker_id" ]]; then
        echo "invalid function call: 'get_broker_endpoint' is called with no broker_id" >&2
        return 1
    fi

    local endpoint
    endpoint=$(aws mq describe-broker \
        --broker-id "$broker_id" \
        --query "BrokerInstances[0].Endpoints[0]" \
        --output text) || return "$?"
    echo "$endpoint"
}