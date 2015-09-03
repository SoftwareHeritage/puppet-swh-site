#!/bin/bash
# deploy.sh: deploy a new version of our puppet environment from git
#
# Merges r10k and other repositories for private stuff
#

set -e

PUPPET_ENV_PATH=/etc/puppet/environments

declare -A GIT_REPOS_TO_MERGE

GIT_REPOS_TO_MERGE+=(
    ["data/private"]="git@git.softwareheritage.org:swh/sysadm/puppet/private/swh-private-data"
)

/usr/bin/r10k deploy environment -p "$@"

for environmentdir in $PUPPET_ENV_PATH/*; do
    cd $environmentdir
    for dest in ${!GIT_REPOS_TO_MERGE[@]}; do
	/usr/bin/git clone ${GIT_REPOS_TO_MERGE[${dest}]} $dest
    done
    cd ..
done
