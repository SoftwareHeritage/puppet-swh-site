class role::objstorage_rancher_node inherits role::swh_server {
  # role::backup
  include profile::swh::deploy::objstorage
  include profile::swh::deploy::objstorage_ceph
  include profile::megacli
  include profile::borg::repository_server

  # role::postgresql_backup
  include profile::postgresql::backup

  # role::rancher_node
  include profile::zfs::kubelet
  include profile::zfs::rancher
  include profile::mountpoints
  include profile::kubernetes
}
