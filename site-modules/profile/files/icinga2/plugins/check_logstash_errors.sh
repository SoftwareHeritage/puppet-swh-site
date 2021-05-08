#!/bin/bash

#
# File managed by puppet. All modifications will be lost.
#
# Check if logstash encountered errors when sending messages
# to its output.
#
# Copyright (c) 2017 The Software Heritage Developers
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

CODE_CRITICAL=2
CODE_OK=0

STATE_CRITICAL=false

LOGSTASH_STATS_URL=http://localhost:9600/_node/stats

ERROR_CODE=0

# JPATH_FAILURE_COUNT=".pipelines.main.plugins.outputs[].bulk_requests.failures"
JPATH_ERROR_COUNT=".pipelines.main.plugins.outputs[].bulk_requests.with_errors"
JPATH_NON_RETRYABLE_FAILURE_COUNT=".pipelines.main.plugins.outputs[].documents.non_retryable_failures"

get_value_from_json() {
    json=$1
    jpath=$2

    if ! jq -r "${jpath}" "${json}"; then
        echo "CRITICAL: unable to parse json file"
        exit ${CODE_CRITICAL}
    fi
}

TMP_FILE=$(mktemp)

trap "rm -f ${TMP_FILE}" EXIT

if ! curl -f -s -o ${TMP_FILE} ${LOGSTASH_STATS_URL}; then
    echo "CRITICAL - Unable to retrieve logstash statistics"
    exit ${CODE_CRITICAL}
fi

NON_RETRYABLE_FAILURES="$(get_value_from_json ${TMP_FILE} ${JPATH_NON_RETRYABLE_FAILURE_COUNT})"
ERRORS="$(get_value_from_json ${TMP_FILE} ${JPATH_ERROR_COUNT})"

if [ "${NON_RETRYABLE_FAILURES}" != "null" ]; then
    STATE_CRITICAL=true
fi

if [ "${ERRORS}" != null ]; then
    STATE_CRITICAL=true
fi

if ${STATE_CRITICAL}; then
    echo "CRITICAL - Logstash has detected some errors in outputs errors=${ERRORS} non_retryable_errors=${NON_RETRYABLE_FAILURES}"
    ERROR_CODE=${CODE_CRITICAL}
else
    echo "OK - No errors detected"
    ERROR_CODE=${CODE_OK}
fi

exit ${ERROR_CODE}
