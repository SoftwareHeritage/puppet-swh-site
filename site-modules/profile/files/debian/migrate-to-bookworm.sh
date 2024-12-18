#!/usr/bin/env bash

# Managed by puppet (module profile::debian_migration), manual changes will be lost

# This script is in charge of migrating a bullseye machine to bookworm.
# It won't do anything if the node is not running bullseye.
#
# The script must be execute by the root user.

set -x

codename=$(lsb_release -c 2>/dev/null | awk '{print $2}')

if [ "${codename}" = "bullseye" ]; then
  pushd /etc/apt

  for pattern_file in sources.list sources.list.d/*.list; do
      # Update the main sources.list
      sed -i 's/bullseye/bookworm/gi' $pattern_file
  done

  git status
  git add .
  git commit -m "migrate from bullseye to bookworm distribution"

  apt update
  apt upgrade --without-new-pkgs -y
  apt full-upgrade --download-only -y
  apt full-upgrade -y

  popd
else
    if [ "${codename}" = "bookworm" ]; then
        echo "Nothing to do. Stop"
        exit 0
    else
        echo "<$codename> cannot be migrated to bookworm. Do nothing."
        exit 1;
    fi
fi
