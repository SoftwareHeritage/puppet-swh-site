# role of zfs snapshot storage server
# only declare a sanoid class to install
# the configuration to manage the snapshot
# retention policy
class role::zfs_snapshots_storage inherits role::swh_base {
  include profile::sanoid::snapshot
}
