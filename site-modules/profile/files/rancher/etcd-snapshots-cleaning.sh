#!/usr/bin/env bash
# vim: ai ts=4 sts=4 sw=4
# This file is managed by puppet. Local modifications will be overwritten.

set -eu
set -o pipefail

# check rke2 command availability
typeset -r RKE2=rke2
[[ -x  $(command -v "$RKE2") ]] || { echo "rke2 command not found." ; exit 1 ; }

# list all etcd-snpashots (not the on-demand) except the 20 newest:
# 3 master nodes on s3 and 1e master node on local file system
SNAPSHOT2DELETE=$("$RKE2" etcd-snapshot ls 2> /dev/null | \
	awk '$1 ~ /^etcd-snapshot-rancher/{print $1}' | head -n -20 | \
	while read -r snap;do echo -n "$snap ";done)

[[ -n $SNAPSHOT2DELETE ]] && \
"$RKE2" etcd-snapshot delete $SNAPSHOT2DELETE

exit 0
