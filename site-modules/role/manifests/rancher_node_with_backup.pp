class role::rancher_node_with_backup inherits role::swh_server {
  # role::backup
  include profile::megacli
  include profile::borg::repository_server

  # role::postgresql_backup
  include profile::postgresql::backup

  # role::rancher_node
  include profile::zfs::kubelet
  include profile::rancher
}
