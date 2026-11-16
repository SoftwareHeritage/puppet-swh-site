# Managed by puppet (module profile::debian_migration), manual changes will be lost

# This script is in charge of migrating a <bookworm> machine to <trixie>.
# It won't do anything but print out what you need to do if the node
# is not running <bookworm>.
#
# The script must be executed by the root user.

set -xe

codename=$(lsb_release -c 2>/dev/null | awk '{print $2}')

case "${codename}" in
    "bullseye")
        echo "<$codename> cannot be migrated to trixie. Do nothing. Please, migrate to bookworm first."
        exit 1
        ;;
    "trixie")
        echo "Already running trixie. Stop"
        exit 0
        ;;
    "bookworm")
        pushd /etc/apt

        for pattern_file in sources.list sources.list.d/*.list; do
            # Update the main sources.list
            sed -i 's/bookworm/trixie/gi' $pattern_file
        done

        (grep bookworm sources.list sources.list.d/*.list && \
             echo "Mentions of <bookworm> still present... Stopping migration." && \
             exit 1) || \
           echo "Configurations *.list updated to <trixie>, proceeding with migration."

        git status
        git add .
        git commit -m "Migrate from bookworm to trixie distribution"

        popd

        (grep bookworm /etc/apt/sources.list /etc/apt/sources.list.d/*.list && \
             echo "Mentions of <bookworm> still present... Stopping migration." && \
             exit 1) || \
           echo "Configurations *.list updated to <trixie>, proceeding with migration."

        # Avoid interactive questions about configuration file This will keep the modified
        # configuration files we have as-is while installing the default updated configuration
        # files for unmodified ones
        export DEBIAN_FRONTEND=noninteractive
        apt update
        apt upgrade --without-new-pkgs -y
        apt dist-upgrade --download-only -y
        apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
            dist-upgrade -y
        ;;
    *)
        echo "<$codename> cannot be migrated to trixie. Do nothing."
        exit 1
        ;;
esac

codename=$(lsb_release -c 2>/dev/null | awk '{print $2}')
if [ "${codename}" = "trixie" ]; then
    echo "Migration to trixie finished!"
    exit 0
else
    echo "Something went wrong. Check the output of this execution."
    exit 1
fi
