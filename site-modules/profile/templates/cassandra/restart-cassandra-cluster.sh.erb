#!/usr/bin/env bash

set -eux

ENVIRONMENT=${1-""}
if [ -z "${ENVIRONMENT}" ]; then
    echo "The environment (<ENVIRONMENT> env variable) must be provided!"
    exit 1;
fi

CONFIG_FILE="/etc/cassandra/${ENVIRONMENT}-env.sh"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Configuration file <$CONFIG_FILE> must be installed!"
    exit 1;
fi

# We source the configuration file which sets the required environment variable
source ${CONFIG_FILE}

if [ -z "${NODES}" ]; then
    echo "The list of nodes to upgrade (<NODES> env variable) must be provided!"
    exit 1
fi
if [ -z "${REMOTE_HOST}" ]; then
    echo "The remote node to use (<REMOTE_HOST> env variable) must be provided!"
    exit 1
fi

if [ -z "${DOMAIN}" ]; then
    echo "The domain (<DOMAIN> env variable) must be provided!"
    exit 1
fi

if [ -z "${CASSANDRA_USER}" ]; then
    echo "The credential login (<CASSANDRA_USER> env variable) must be provided!"
    exit 1
fi

if [ -z "${CASSANDRA_PASSWORD}" ]; then
    echo "The credential passwd (<CASSANDRA_PASSWORD>) env variable must be provided!"
    exit 1
fi

# Nodetool
NODETOOL_CMD=/opt/cassandra/bin/nodetool
# Instance service name
INSTANCE=instance1
# seconds
DELAY_BETWEEN_NODE=60

get_coordinator() {
    local node_to_restart=$1
    for NODE in $NODES; do
        if [ "${NODE}" != "${node_to_restart}" ]; then
            echo "${NODE}.${DOMAIN}"
            return
        fi
    done
}

wait_for_status() {
    local node=$1
    local expected_status=$2

    status="undefined"
    while [ "${status}" != "${expected_status}" ]; do
        echo -n "."
        sleep 5
        status="$(ssh ${COORDINATOR} ${NODETOOL_CMD} -h ${COORDINATOR} -u ${CASSANDRA_USER} --password ${CASSANDRA_PASSWORD} status -r | grep ${node} | cut -b1)"
    done
}

for NODE_NAME in $NODES; do
    NODE="$NODE_NAME.$DOMAIN"
    COORDINATOR="$(get_coordinator ${NODE_NAME})"
    SECONDS=0

    echo "Launching a drain on ${NODE}."
    ssh -t ${COORDINATOR} ${NODETOOL_CMD} \
        --host ${NODE} \
        --username ${CASSANDRA_USER} \
        --password ${CASSANDRA_PASSWORD} \
        drain

    echo "Restarting ${NODE}."
    ssh -t "${NODE}" systemctl restart cassandra@$INSTANCE

    echo -n "Waiting for the node to be down."
    wait_for_status "${NODE}" D
    echo ""
    echo "Node ${NODE} was correctly stopped in ${SECONDS}s."

    SECONDS=0
    echo -n "Waiting for node ${NODE} to be up."
    wait_for_status "${NODE}" U
    echo ""
    echo "Node ${NODE} successfully restarted in ${SECONDS}s."

    echo "Waiting ${DELAY_BETWEEN_NODE} before restarting next node."
    sleep ${DELAY_BETWEEN_NODE}
done

echo "Done, cluster completely restarted!"
