#!/bin/sh
#
# Copyright (c) 2018 The Software Heritage Developers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This program checks the state of an Elasticsearch cluster

# Icinga exit codes
# 0: OK
# 1: WARNING
# 2: CRITICAL
# 3: UNKNOWN

CURL=/usr/bin/curl

HOST_NAMES=""
HOST_NAMES="${HOST_NAMES} esnode1.internal.softwareheritage.org"
HOST_NAMES="${HOST_NAMES} esnode2.internal.softwareheritage.org"
HOST_NAMES="${HOST_NAMES} esnode3.internal.softwareheritage.org"

for host in ${HOST_NAMES}
do
	result_str=`${CURL} -s -m 2 "http://${host}:9200/_cluster/health"`
	result_code=$?
	if [ ${result_code} = 0 ]; then
		# Directly go to cluster state parsing stage
		break;
	fi
done

# State parsing stage
# If all connections did timeout, return state unknown
if [ ${result_code} -ne 0 ]; then
	echo "Failed to reach all cluster members"
	exit 3
fi

cluster_name=`echo ${result_str} | tr -d \" | cut -f 1 -d "," | cut -f 2 -d ":"`
cluster_status=`echo ${result_str} | tr -d \" | cut -f 2 -d "," | cut -f 2 -d ":"`

echo "Elasticsearch cluster ${cluster_name} is ${cluster_status}."

case "${cluster_status}" in
	"green")
		exit 0;;
	"yellow")
		exit 1;;
	"red")
		exit 2;;
esac

# When in doubt, return state unknown
exit 3
