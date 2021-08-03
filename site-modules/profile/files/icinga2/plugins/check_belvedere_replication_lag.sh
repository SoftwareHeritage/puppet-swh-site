#!/bin/bash

#
# File managed by puppet. All modifications will be lost.

# Wrapper calling check_prometheus_metric.sh with the harcoded prometheus query
# incorrectly parsed when passed to vars.check_prometheus_metric_query

PROGPATH=$(dirname $0)

while getopts ':H:n:c:w:' OPT "$@"
do
    case ${OPT} in
        H)  PROMETHEUS_SERVER="$OPTARG" ;;
        n)  METRIC_NAME="$OPTARG" ;;
        c)  CRITICAL_THRESHOLD=${OPTARG}
            ;;
        w) WARNING_THRESHOLD=${OPTARG}
            ;;
        *) echo "Invalid option ${OPT}"
           exit 1
           ;;
    esac
done

QUERY='sum(sql_pg_stat_replication{instance="belvedere.internal.softwareheritage.org", host=":5433", application_name="softwareheritage_replica"})'

${PROGPATH}/check_prometheus_metric.sh -H ${PROMETHEUS_SERVER} -q "${QUERY}" -w ${WARNING_THRESHOLD} -c ${CRITICAL_THRESHOLD} -n "${METRIC_NAME}" -t vector
