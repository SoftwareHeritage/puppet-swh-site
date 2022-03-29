#!/bin/bash

##
# File managed by puppet (class profile::azure_billing_report), changes will be lost.

set -e

pushd "${DATA_DIRECTORY}"

CSV_FILE=${DATA_DIRECTORY}/AzureUsage.csv
echo "Cleanup previous csv file..."
rm -fv ${CSV_FILE}

if [ ! -e "${CSV_FILE}" ]; then
    echo "Getting new statistics from azure portal..."
    ${DATA_DIRECTORY}/.venv/bin/python3 ${INSTALL_DIRECTORY}/get_csv.py
else
    echo "${CSV_FILE} already exists, reusing it..."
fi

echo "Generating report..."

pushd ${INSTALL_DIRECTORY}
${DATA_DIRECTORY}/.venv/bin/python3 ${INSTALL_DIRECTORY}/compute_stats.py ${DATA_DIRECTORY}

echo "Report refreshed."
