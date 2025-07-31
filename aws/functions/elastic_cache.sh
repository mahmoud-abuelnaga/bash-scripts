#!/bin/bash

# constants
ELASTIC_CACHE_PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources
source "$ELASTIC_CACHE_PREFIX/../../general/functions/constants.sh"

# functions
create_cache_subnet_group() {
    local name="$1"
    local description="$2"
    local subnet_ids=("${@:3}")

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_cache_subnet_group' is called without a group name" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_cache_subnet_group' is called without a description" >&2
        return 1
    fi

    if [[ ${#subnet_ids[@]} -lt 2 ]]; then
        echo "invalid function call: 'create_cache_subnet_group' is called with less than 2 subnet ids" >&2
        return 1
    fi

    local result
    result=$(aws elasticache create-cache-subnet-group \
        --cache-subnet-group-name "$name" \
        --cache-subnet-group-description "$description" \
        --subnet-ids "${subnet_ids[@]}" \
        --query "CacheSubnetGroup.CacheSubnetGroupName" \
        --output text) || return "$?"

    echo "$result"
}

create_cache_parameter_group() {
    local name="$1"
    local description="$2"
    local family="$3"

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_cache_parameter_group' is called without a group name" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_cache_parameter_group' is called without a description" >&2
        return 1
    fi

    if [[ -z "$family" ]]; then
        echo "invalid function call: 'create_cache_parameter_group' is called without a family" >&2
        return 1
    fi

    local result
    result=$(aws elasticache create-cache-parameter-group \
        --cache-parameter-group-name "$name" \
        --description "$description" \
        --cache-parameter-group-family "$family" \
        --query "CacheParameterGroup.CacheParameterGroupName" \
        --output text) || return "$?"

    echo "$result"
}

create_cache_cluster() {
    local name="$1"
    local engine="$2"
    local node_type="$3"
    local num_nodes="$4"
    local subnet_group_name="$5"
    local region="$6"
    local security_group_ids=("${@:7}")

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without a cluster name" >&2
        return 1
    fi

    if [[ -z "$engine" ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without an engine" >&2
        return 1
    fi

    if [[ -z "$node_type" ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without a node type" >&2
        return 1
    fi

    if [[ -z "$num_nodes" ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without a number of nodes" >&2
        return 1
    fi

    if [[ -z "$subnet_group_name" ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without a subnet group name" >&2
        return 1
    fi

    if [[ -z "$region" ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without a region" >&2
        return 1
    fi

    if [[ ${#security_group_ids[@]} -lt 1 ]]; then
        echo "invalid function call: 'create_cache_cluster' is called without a security group id" >&2
        return 1
    fi

    local result
    result=$(aws elasticache create-cache-cluster \
        --cache-cluster-id "$name" \
        --engine "$engine" \
        --cache-node-type "$node_type" \
        --num-cache-nodes "$num_nodes" \
        --cache-subnet-group-name "$subnet_group_name" \
        --region "$region" \
        --security-group-ids "${security_group_ids[@]}" \
        --query "CacheCluster.CacheClusterId" \
        --output text) || return "$?"

    echo "$result"
}

wait_for_cache_cluster() {
    local cluster_id="$1"

    if [[ -z "$cluster_id" ]]; then
        echo "invalid function call: 'wait_for_cache_cluster' is called without a cluster id" >&2
        return 1
    fi

    aws elasticache wait cache-cluster-available --cache-cluster-id "$cluster_id" >"$DEV_NULL" || return "$?"
}

get_cache_cluster_endpoint() {
    local cluster_id="$1"
    if [[ -z "$cluster_id" ]]; then
        echo "invalid function call: 'get_cache_cluster_endpoint' is called with no cluster id" >&2
        return 1
    fi

    local endpoint
    endpoint=$(aws elasticache describe-cache-clusters --cache-cluster-id "$cluster_id" --show-cache-node-info --query "CacheClusters[0].ConfigurationEndpoint.Address" --output text) || return "$?"
    echo "$endpoint"
}