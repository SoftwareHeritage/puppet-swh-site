#!/usr/bin/env bash

# Managed by puppet (module profile::debian_migration), manual changes will be lost

# This script is in charge of migrating a bullseye machine to bookworm.
# It won't do anything if the node is not running bullseye.
#
# The script must be executed by the root user.

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

  # Avoid interactive questions about configuration file This will keep the modified
  # configuration files we have as-is while installing the default updated configuration
  # files for unmodified ones
  export DEBIAN_FRONTEND=noninteractive

  popd
  apt update
  apt upgrade --without-new-pkgs -y
  apt dist-upgrade --download-only -y
  apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
      dist-upgrade -y
else
    if [ "${codename}" = "bookworm" ]; then
        echo "Nothing to do. Stop"
        exit 0
    else
        echo "<$codename> cannot be migrated to bookworm. Do nothing."
        exit 1;
    fi
fi
