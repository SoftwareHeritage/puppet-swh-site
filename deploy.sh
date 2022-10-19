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

/usr/bin/r10k deploy environment -p "$@"

for environmentdir in $PUPPET_ENV_PATH/*; do
    cd $environmentdir
    for dest in ${!GIT_REPOS_TO_MERGE[@]}; do
	      if [ -d $dest/.git ]; then
	          cd $dest
            /usr/bin//git reset --hard HEAD
	          /usr/bin/git pull
	          cd $environmentdir
	      else
	          /usr/bin/git clone ${GIT_REPOS_TO_MERGE[${dest}]} $dest
	      fi
    done
    cd ..
done

cp $PUPPET_ENV_PATH/production/deploy.sh /usr/local/bin
