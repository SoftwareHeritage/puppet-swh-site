#!/bin/bash
# deploy.sh: deploy a new version of our puppet environment from git

set -e

PUPPET_ENV_PATH=$(puppet config print environmentpath)

/usr/bin/r10k deploy environment -p "$@"

for environmentdir in $PUPPET_ENV_PATH/*; do
    pushd $environmentdir
    if [ -d data/private ]; then
        rm -r data/private
    fi
    popd
done

cp $PUPPET_ENV_PATH/production/deploy.sh /usr/local/bin
