class role::rancher_node_with_database inherits role::swh_database {
  # original bare database role
  include profile::postgresql::server
  include profile::pgbouncer
  include profile::postgresql::client

  # rancher profile
  include profile::zfs::kubelet
  include profile::rancher
}
