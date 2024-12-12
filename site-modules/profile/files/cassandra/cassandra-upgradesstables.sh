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

get_coordinator() {
    local node_to_restart=$1
    for NODE in $NODES; do
        if [ "${NODE}" != "${node_to_restart}" ]; then
            echo "${NODE}.${DOMAIN}"
            return
        fi
    done
}

for NODE_NAME in $NODES; do
    NODE="$NODE_NAME.$DOMAIN"
    COORDINATOR="$(get_coordinator ${NODE_NAME})"
    SECONDS=0

    echo "Launching an upgradesstables on ${NODE}."
    ssh -t ${COORDINATOR} ${NODETOOL_CMD} \
        --host ${NODE} \
        --username ${CASSANDRA_USER} \
        --password ${CASSANDRA_PASSWORD} \
        upgradesstables

    echo "upgradesstables done in ${NODE}, moving on to the next node."
done

echo "Done, cluster completely upgradesstables!"
