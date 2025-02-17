#!/usr/bin/env bash

# Use:
# $0 CERTNAME ...

# Example:
# $0 storage0.internal.staging.swh.network db0.internal.staging.swh.network

set -x

server_list=$(echo "$@" | tr -s '[:blank:]' ',')

echo puppetserver ca clean --certname "${server_list}"
