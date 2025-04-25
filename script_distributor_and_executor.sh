#!/bin/bash

script_path=$1
script_args_count=$2
shift 2

script_args=()
for ((i=0;i<script_args_count;i++)); do
        script_args+=("$1")
        shift 1
done

host_dest_pairs=$#
for (( i=0;i<host_dest_pairs;i+=2 )); do
        host=$1
        dest=$2
        shift 2

        # echo $host $dest
        # ssh $host $dest touch $dest
        scp "$script_path" "$host:$dest"
        ssh "$host" "$dest" "${script_args[@]}"
done