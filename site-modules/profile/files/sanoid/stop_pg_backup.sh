#!/bin/bash
#
# File managed by puppet. All modifications will be lost.

## - stop the postgresql backup
## - replace the wal snapshot if it was taken before the postgresql snapshot 
##   to ensure all the needed wals are present

set -ex
DATASET="${SANOID_TARGET}"
SNAPSHOT_NAME="${SANOID_SNAPNAME:-backup}"

echo "$0 start"

sudo -i -u postgres psql -c "select pg_stop_backup()"

echo "Testing wal shapshot to ensure it is posterior"
# as sanoid does not guaranty the snapshot orders

if [ -n "${DATASET}" ]; then
	WAL_DATASET="${DATASET}/wal" # by convention
	FULL_SNAPSHOT_NAME="${WAL_DATASET}@${SNAPSHOT_NAME}"
	if zfs list -t snapshot "${FULL_SNAPSHOT_NAME}"; then
		zfs destroy "${FULL_SNAPSHOT_NAME}"
		zfs snapshot "${FULL_SNAPSHOT_NAME}"
	fi
else
	echo "Dataset name not set"
	exit 1
fi

echo "$0 done"
