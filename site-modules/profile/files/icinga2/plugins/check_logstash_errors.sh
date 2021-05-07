#!/bin/bash

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
