#!/usr/bin/env bash

##
# File managed by puppet (class profile::jenkins::server), changes will be lost.
##

set -e

clean_shared_cachedir () {
  local dir="$1"
  local threshold=$2

  # cleanup pip cache
  find "$dir/pip" -mindepth 1 -type f -ctime +$threshold -delete
  # cleanup empty directories (recursively)
  find "$dir/pip" -mindepth 1 -depth -type d -empty -delete
  find "$dir/pip" -mindepth 1 -depth -type d -empty -delete
  find "$dir/pip" -mindepth 1 -depth -type d -empty -delete

  # cleanup yarn cache
  find "$dir/yarn/v6" -mindepth 1 -maxdepth 1 -type d -ctime +$threshold -exec rm -r {} \+

  # cleanup old Cypress versions
  (cd "$dir/Cypress"; ls -1 | sort -V | head -n -1 | xargs -r rm -r)

  # cleanup old pre-commit repositories
  find "$dir/pre-commit" -mindepth 1 -maxdepth 1 -type d -ctime +$threshold -exec rm -r {} \+
}

prune_docker () {
  docker system prune --filter 'label!=keep' --volumes --force

  # Somehow docker system prune --volumes is missing some dangling volumes...
  docker volume list --filter dangling=true --format json | jq -r 'select(.Labels!="keep=true")|.Name' | xargs -r docker volume rm
}

# Prune dangling layers and volumes once
prune_docker

# Update tagged docker images; do not croak if pulling fails
docker image ls \
    | tail -n +2 \
    | awk '{if ($1 !~ /^app-manager|swh\/|(swh-jenkins(-test)?\/|softwareheritage\/)/ && $2 != "<none>") { print $1":"$2 }}' \
    | xargs -r -n1 docker image pull \
  || true

# To avoid timezone shift shenanigans (when triggered around midnight)
today=$(date --date '13:00' +%Y%m%d)
yesterday=$(date --date 'yesterday 13:00' +%Y%m%d)

# Drop specific softwareheritage docker images (which accumulate over time)
# except for the last 2 days, and the latest tag
docker image ls \
    | awk '{
        if ($1 ~ /^(softwareheritage|container-registry.softwareheritage.org|swh-jenkins(-test)?)\// && $2 !~ '"/$today|$yesterday|latest/"') {
                if ($2 == "<none>") {
                        print $3
                } else {
                        print $1":"$2
                }
        }
      }' \
    | xargs -r docker rmi

# Prune more dangling layers
prune_docker

if [ -d /var/lib/docker/volumes/shared-jenkins-cachedir/_data ]; then
	# clean up cachedir data older than 30 days
	clean_shared_cachedir /var/lib/docker/volumes/shared-jenkins-cachedir/_data 30
fi
