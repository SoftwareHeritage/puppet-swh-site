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
  (cd $dir/Cypress; ls -1 | sort -V | head -n -1 | xargs -r rm -r)

  # cleanup old pre-commit repositories
  find "$dir/pre-commit" -mindepth 1 -maxdepth 1 -type d -ctime +$threshold -exec rm -r {} \+
}

# Update tagged docker images
docker image ls \
    | tail -n +2 \
    | awk '{if ($2 != "<none>") { print $1":"$2 }}' \
    | xargs -r -n1 docker image pull

# To avoid timezone shift shenanigans (when triggered around midnight)
today=$(date --date '13:00' +%Y%m%d)
yesterday=$(date --date 'yesterday 13:00' +%Y%m%d)

# Drop specific softwareheritage docker images (which accumulates over time)
# except for the last 2 days. If triggered around midnight, that could drop
# everything in the end, so let's stay safe and keep only 2 days.
# We also keep the latest tag
docker image ls \
    | grep -E "(softwareheritage/(base|web|replayer)|container-registry.softwareheritage.org/swh/infra/ci-cd)" \
    | grep -v $today \
    | grep -v $yesterday \
    | grep -v "latest" \
    | awk '{if ($2 == "<none>") { print $3 } else { print $1":"$2 }}' \
    | xargs -r docker rmi

docker system prune --filter 'label!=keep' --volumes --force

if [ -d /var/lib/docker/volumes/shared-jenkins-cachedir/_data ]; then
	# clean up cachedir data older than 30 days
	clean_shared_cachedir /var/lib/docker/volumes/shared-jenkins-cachedir/_data 30
fi

