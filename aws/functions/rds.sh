#!/bin/bash

# constants
RDS_PREFIX="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# sources
# shellcheck disable=SC1091
source "$RDS_PREFIX/ec2.sh"
# shellcheck disable=SC1091
source "$RDS_PREFIX/vpc.sh"
# shellcheck disable=SC1091
source "$RDS_PREFIX/security_group.sh"

# functions
create_rds_subnet_group() {
    local name="$1"
    local description="$2"
    local subnets_ids=("${@:3}")

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_rds_subnet_group' is called without a name" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_rds_subnet_group' is called without a description" >&2
        return 1
    fi

    if [[ ${#subnets_ids[@]} -lt 2 ]]; then
        echo "invalid function call: 'create_rds_subnet_group' is called with less than 2 subnet ids" >&2
        return 1
    fi

    local result
    result=$(aws rds create-db-subnet-group \
        --db-subnet-group-name "$name" \
        --db-subnet-group-description "$description" \
        --subnet-ids "${subnets_ids[@]}" \
        --query "DBSubnetGroup.DBSubnetGroupName" \
        --output text) || return "$?"

    echo "$result"
}

create_rds_parameter_group() {
    local name="$1"
    local description="$2"
    local family="$3"

    if [[ -z "$name" ]]; then
        echo "invalid function call: 'create_rds_parameter' is called without a name" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_rds_parameter' is called without a description" >&2
        return 1
    fi

    if [[ -z "$family" ]]; then
        echo "invalid function call: 'create_rds_parameter' is called without a family" >&2
        return 1
    fi

    local result
    result=$(aws rds create-db-parameter-group \
        --db-parameter-group-name "$name" \
        --description "$description" \
        --db-parameter-group-family "$family" \
        --query "DBParameterGroup.DBParameterGroupName" \
        --output text) || return "$?"

    echo "$result"
}

create_rds_instance() {
    local identifier="$1"
    local instance_class="$2"
    local engine="$3"
    local engine_version="$4"
    local username="$5"
    local password="$6"
    local allocated_storage="$7"
    local storage_type="$8"
    local subnet_group_name="$9"
    local security_group_ids_str="${10}"
    local backup_retention_period="${11:-0}"
    local is_publicly_accessible="${12:-false}"
    local is_multi_az="${13:-false}"
    local availability_zone="${14}"

    if [[ -z "$identifier" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without an identifier" >&2
        return 1
    fi

    if [[ -z "$instance_class" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without an instance class" >&2
        return 1
    fi

    if [[ -z "$engine" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without an engine" >&2
        return 1
    fi

    if [[ -z "$engine_version" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without an engine version" >&2
        return 1
    fi

    if [[ -z "$username" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without a username" >&2
        return 1
    fi

    if [[ -z "$password" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without a password" >&2
        return 1
    fi

    if [[ -z "$allocated_storage" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without an allocated storage" >&2
        return 1
    fi

    if [[ -z "$storage_type" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without a storage type" >&2
        return 1
    fi

    if [[ -z "$subnet_group_name" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without a subnet group name" >&2
        return 1
    fi

    if [[ -z "$security_group_ids_str" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without security group ids" >&2
        return 1
    fi

    if [[ -z "$backup_retention_period" || "$backup_retention_period" -lt 0 ]]; then
        echo "invalid function call: 'create_rds_instance' is called with an invalid backup retention period" >&2
        return 1
    fi

    if [[ -z "$is_publicly_accessible" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without a publicly accessible flag" >&2
        return 1
    fi

    if [[ -z "$is_multi_az" ]]; then
        echo "invalid function call: 'create_rds_instance' is called without a multi az flag" >&2
        return 1
    fi

    local security_group_ids
    read -ra security_group_ids <<<"$security_group_ids_str"

    if [[ ${#security_group_ids[@]} -eq 0 ]]; then
        echo "invalid function call: 'create_rds_instance' is called with no security groups" >&2
        return 1
    fi

    local cmd
    cmd=$(
        cat <<EOF
        aws rds create-db-instance \
            --db-instance-identifier "$identifier" \
            --db-instance-class "$instance_class" \
            --engine "$engine" \
            --engine-version "$engine_version" \
            --master-username "$username" \
            --master-user-password "$password" \
            --allocated-storage "$allocated_storage" \
            --storage-type "$storage_type" \
            --db-subnet-group-name "$subnet_group_name" \
            --vpc-security-group-ids "${security_group_ids[@]}" \
            --backup-retention-period "$backup_retention_period" \
            --query "DBInstance.DBInstanceIdentifier" \
            --output text
EOF
    )

    if [[ "$is_publicly_accessible" == "true" ]]; then
        cmd+=" --publicly-accessible"
    else
        cmd+=" --no-publicly-accessible"
    fi

    if [[ "$is_multi_az" == "true" ]]; then
        cmd+=" --multi-az"
    else
        cmd+=" --no-multi-az"
    fi

    if [[ -n "$availability_zone" ]]; then
        cmd+=" --availability-zone $availability_zone"
    fi

    local db_instance_identifier
    db_instance_identifier=$(eval "$cmd") || return "$?"

    echo "$db_instance_identifier"
}

get_rds_endpoint() {
    local rds_identifier="$1"
    if [[ -z "$rds_identifier" ]]; then
        echo "invalid function call: 'get_rds_endpoint' is called with no rds_identifier" >&2
        return 1
    fi

    local endpoint
    endpoint=$(aws rds describe-db-instances --db-instance-identifier "$rds_identifier" --query "DBInstances[0].Endpoint.Address" --output text) || return "$?"

    echo "$endpoint"
}

wait_for_rds_instance() {
    local rds_identifier="$1"
    if [[ -z "$rds_identifier" ]]; then
        echo "invalid function call: 'wait_for_rds_instance' is called with no rds_identifier" >&2
        return 1
    fi

    aws rds wait db-instance-available --db-instance-identifier "$rds_identifier" || return "$?"
}

get_rds_vpc_id() {
    local rds_identifier="$1"
    if [[ -z "$rds_identifier" ]]; then
        echo "invalid function call: 'get_rds_vpc_id' is called with no rds_identifier" >&2
        return 1
    fi

    local vpc_id
    vpc_id=$(aws rds describe-db-instances \
                --db-instance-identifier "$rds_identifier" \
                --query "DBInstances[].DBSubnetGroup.VpcId" \
                --output text) || return "$?"

    echo "$vpc_id"
}

get_rds_sgs() {
    local rds_identifier="$1"
    if [[ -z "$rds_identifier" ]]; then
        echo "invalid function call: 'get_rds_sg' is called with no rds_identifier" >&2
        return 1
    fi

    local sgs
    sgs=$(aws rds describe-db-instances \
            --db-instance-identifier "$rds_identifier" \
            --query 'DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId' \
            --output text) || return "$?"

    echo "$sgs"
}

intialize_database() {
    local rds_identifier="$1"
    local username="$2"
    local password="$3"
    local sql_script_path="$4"
    local database_to_execute_script_on="$5"
    local db_type="$6"

    if [[ -z "$rds_identifier" ]]; then
        echo "invalid function call: 'intialize_database' is called with no rds_identifier" >&2
        return 1
    fi

    if [[ -z "$username" ]]; then
        echo "invalid function call: 'intialize_database' is called with no username" >&2
        return 1
    fi

    if [[ -z "$password" ]]; then
        echo "invalid function call: 'intialize_database' is called with no password" >&2
        return 1
    fi

    if [[ -z "$sql_script_path" ]]; then
        echo "invalid function call: 'intialize_database' is called with no sql_script_path" >&2
        return 1
    fi

    if [[ -z "$db_type" ]]; then
        echo "invalid function call: 'intialize_database' is called with no db_type" >&2
        return 1
    fi

    if [[ "$db_type" != "mysql" ]]; then
        echo "invalid function call: 'intialize_database' only supports mysql" >&2
        return 1
    fi

    local endpoint
    endpoint=$(get_rds_endpoint "$rds_identifier") || return "$?"

    local sgs
    sgs=$(get_rds_sgs "$rds_identifier") || return "$?"
    local sgs_arr=()
    read -ra sgs_arr <<< "$sgs"
    local sel_sg="${sgs_arr[0]}"

    local vpc_id
    vpc_id=$(get_rds_vpc_id "$rds_identifier") || return "$?"

    local public_subnets_ids
    public_subnets_ids=$(get_public_subnets_of_vpc "$vpc_id") || return "$?"
    local public_subnets_ids_arr=()
    read -ra public_subnets_ids_arr <<< "$public_subnets_ids"
    local sel_public_subnet_id="${public_subnets_ids_arr[0]}"
    
    local jumper_server_details
    jumper_server_details=$(create_ubuntu_jumper_server_with_mysql_client "" "$vpc_id" "$sel_public_subnet_id") || return "$?"

    local jumper_server_id jumper_server_sg jumper_server_key_name jumper_server_public_ip
    read -r jumper_server_id jumper_server_sg jumper_server_key_name jumper_server_public_ip <<< "$jumper_server_details" || return "$?"

    allow_connection_to_mysql_from_another_sg "$sel_sg" "$jumper_server_sg" || return "$?"
    scp -i "$jumper_server_key_name.pem" "$sql_script_path" "ubuntu@$jumper_server_public_ip:/tmp/db.sql" >&2 || return "$?"
    ssh -i "$jumper_server_key_name.pem" "ubuntu@$jumper_server_public_ip" "mysql -h $endpoint -u $username -p$password $database_to_execute_script_on < /tmp/db.sql" >&2 || return "$?"
    disallow_connection_to_mysql_from_another_sg "$sel_sg" "$jumper_server_sg" || return "$?"

    delete_jumper_server "$jumper_server_id" || return "$?"
    rm -f "$jumper_server_key_name.pem"
}