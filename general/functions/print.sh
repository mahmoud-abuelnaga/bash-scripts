#!/bin/bash

print_error() {
    local msg="$1"
    echo "error: $msg" >&2   
}

print_header() {
    local msg="$1"
    printf "\n##### %s #####\n" "$msg"
}

print_msg() {
    local msg="$1"
    printf "\n==> %s\n" "$msg"
}