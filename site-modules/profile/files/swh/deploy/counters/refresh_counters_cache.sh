#!/bin/bash

##
# File managed by puppet (class profile::swh::deploy::counters), changes will be lost.

set -e

cache_file=$1
static_file=$2

static_file_stanza=""
if [ -n "${static_file}" ]; then
    static_file_stanza=", \"static_file\": \"${static_file}\""
fi

tmp_file=$(mktemp)

trap "rm -f ${tmp_file}" EXIT

cat >"${tmp_file}" <<EOF
{
    "cache_file": "${cache_file}", 
    "objects": ["content", "origin", "revision"]
    ${static_file_stanza}
}
EOF

curl -s -XPOST -H 'Content-Type: application/json' http://localhost:5011/refresh_history -d @"${tmp_file}"
