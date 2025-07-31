#!/bin/bash

die() {
    local msg="${1:-untitiled error}"
    local code="${2:-1}"

    echo "error: $msg" >&2
    exit "$code"
}

get_my_ip() {
    local ip
    ip=$(curl -s https://api.ipify.org) || return "$?"
    echo "$ip"
}