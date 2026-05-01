#!/bin/bash

# 🎯 display as left-align key-value pair
display_key_value() {
    local key=$1
    local value=$2

    printf "  %-15s %s\n" "$key" "$value"
}

# 🎯 display a formatted headline
display_headline() {
    local headline="$1"
    echo
    echo "$headline:"
    echo
}