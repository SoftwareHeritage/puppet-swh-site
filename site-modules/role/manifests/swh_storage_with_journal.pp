class role::swh_storage_with_journal inherits role::swh_server {
  include profile::postgresql::client
  include profile::swh::deploy::journal::backfill

  # journal
  include profile::zookeeper
  include profile::kafka::broker

  # (temporary) storage/objstorage related
  # this will be migrated away
  include profile::swh::deploy::storage
  include profile::swh::deploy::objstorage

  # Make this node a rancher agent too
  include profile::zfs::kubelet
  include profile::zfs::rancher
  include profile::mountpoints
  include profile::kubernetes
}
