#!/bin/bash -x
#
# File managed by puppet (class ::profile::journalbeat::index_template_manager), changes will be lost.

# Generate the journalbeat index template and create it in elasticsearch
# Save the json in the /var/lib/journalbeat directory 
# Params:
#  - ES HOST
#  - template name
#  - index template
# Output:
#  - /var/lib/journalbeat/<template name>.json
set -e

if [ $# -ne 3 ]; then
    echo "Usage: $0 <ES_URL> ><template name> <index pattern>"
    echo "ex: $0 http://esnode1:9200 swh_workers-7.15.2 'swh_workers-7.15.2-*'"
    exit 1
fi

ES_HOST=$1
TEMPLATE_NAME=$2
INDEX_PATTERN=$3

TEMPLATE_FILE="${TEMPLATE_NAME}.json"
JOURNAL_BEAT_HOME=/var/lib/journalbeat

# generating 
journalbeat export template \
    -E setup.ilm.enabled=false \
    -E setup.template.name="${TEMPLATE_NAME}" \
    -E setup.template.pattern="${INDEX_PATTERN}" > "/tmp/${TEMPLATE_FILE}"


curl -XPOST -H 'Content-Type: application/json' \
  "${ES_HOST}/_template/${TEMPLATE_NAME}" -d@"/tmp/${TEMPLATE_FILE}"

mv /tmp/${TEMPLATE_FILE} ${JOURNAL_BEAT_HOME}

exit 0
