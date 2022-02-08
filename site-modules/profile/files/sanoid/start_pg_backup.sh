#!/bin/bash
#
# File managed by puppet. All modifications will be lost.

set -ex

BACKUP_NAME="${SANOID_SNAPNAME:-backup}"

sudo -i -u postgres psql -c "select pg_start_backup('$BACKUP_NAME', true)"
