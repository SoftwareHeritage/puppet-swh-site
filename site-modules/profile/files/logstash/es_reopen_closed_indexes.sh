#!/bin/bash

#
# File managed by puppet (profile::logstash). All modifications will be lost.

# Script to reopen and eventually unfreeze frozen indices in elasticsearch
# reason:
# - closed index or frozen index can't be written to
# - journalbeat replays old logs when a machine is rebooted which creates icinga alerts
# - source of this behavior ^ is not determined yet so we work around it with the following script

ES_SERVER=192.168.100.61:9200
LOGFILE=/var/log/logstash/logstash-plain.log
LIMIT=$1

function filter_index_name() {
    # extract the index name for the lines:
    # new log format : ...  "type" =>" cluster_block_exception","reason " => "  index  [ swh_workers-7.15.2-2021.11.07 ]...
    # old log format : ... ({type  =>  cluster_block_exception, reason    =>    index  [ systemlogs-2021.11.09         ] blocked...
    #                                         .*                reason "? => "? index \[     ([.a-z0-9_\-]+)          \]    .*
    sed -r 's/.*"index"=>"([a-z0-9\-\.\-]+)".*/\1/g' | sort | uniq
}

function log_indices() {
    if [ -z "$1" ]; then
        journalctl -x -u logstash | grep "cluster_block" | filter_index_name
    else
        tail -n$1 $LOGFILE | grep "cluster_block" | filter_index_name
    fi
}

while true; do
    date
    echo "Searching indices to reopen..."
    INDICES="$(log_indices $LIMIT)"
    echo "Found: ${INDICES}"

    for i in $INDICES; do
        echo "Reopening $i"
        printf "\tOpening : "
        curl -f -s -XPOST "$ES_SERVER/${i}/_open" || echo -n "failure"
        echo "" # new line after ES response
        printf "\tUnfreeze: "
        curl -f -s -XPOST "$ES_SERVER/${i}/_unfreeze" || echo -n "failure"
        echo "" # new line after ES response
    done
    echo "Done"
    sleep 30
done
