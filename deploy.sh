#!/bin/bash
# deploy.sh: deploy a new version of our puppet environment from git
#
# Merges r10k and other repositories for private stuff
#

set -e

PUPPET_ENV_PATH=$(puppet config print environmentpath)

declare -A GIT_REPOS_TO_MERGE

GIT_REPOS_TO_MERGE+=(
    ["data/private"]="git@gitlab.softwareheritage.org:infra/puppet/puppet-swh-private-data.git"
)

GIT=/usr/bin/git

/usr/bin/r10k deploy environment -p "$@"

for environmentdir in $PUPPET_ENV_PATH/*; do
    pushd $environmentdir
    for dest in ${!GIT_REPOS_TO_MERGE[@]}; do
        if [ -d $dest/.git ]; then
            pushd $dest
            $GIT remote set-url origin ${GIT_REPOS_TO_MERGE[${dest}]}
            $GIT reset --hard HEAD
            $GIT pull
            popd
        else
            $GIT clone ${GIT_REPOS_TO_MERGE[${dest}]} $dest
        fi
    done
    popd
done

cp $PUPPET_ENV_PATH/production/deploy.sh /usr/local/bin
