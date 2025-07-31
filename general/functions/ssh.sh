#!/bin/bash

# functions
ssh_add_host_to_known_hosts() {
    local host="$1"
    if [[ -z "$host" ]]; then
        echo "invalid function call: 'ssh_add_host_to_known_hosts' is called with no host" >&2
        return 1
    fi

    local fingerprint
    fingerprint=$(ssh-keyscan -H "$host") || return "$?"
    
    echo "$fingerprint" >> "$HOME/.ssh/known_hosts"
    return 0
}