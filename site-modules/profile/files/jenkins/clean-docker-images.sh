#!/usr/bin/env bash

##
# File managed by puppet (class profile::jenkins::server), changes will be lost.
##

set -x

# To avoid timezone shift shenanigans (when triggered around midnight)
today=$(date --date '13:00' +%Y%m%d)
yesterday=$(date --date 'yesterday 13:00' +%Y%m%d)

# Drop specific softwareheritage docker images (which accumulates over time)
# except for the last 2 days. If triggered around midnight, that could drop
# everything in the end, so let's stay safe and keep only 2 days.
# We also keep the latest tag
images_to_drop=$(docker image ls \
    | grep -E "softwareheritage/(base|web|replayer)" \
    | grep -v $today \
    | grep -v $yesterday \
    | grep -v "latest")

# To circumvent warning about `docker rmi` not being too happy when called with empty data
if [ ! -z "$images_to_drop" ]; then
    echo $images_to_drop \
    | awk '{print $1":"$2}' \
    | xargs docker rmi
fi

# Finally prune dangling refs.
docker system prune --filter 'label!=keep' --volumes --force
