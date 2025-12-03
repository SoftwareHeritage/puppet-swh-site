class role::rancher_node_with_database inherits role::swh_database_with_pgbouncer {
  # rancher profile
  include profile::zfs::kubelet
  include profile::rancher
}
