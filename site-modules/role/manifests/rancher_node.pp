class role::rancher_node inherits role::swh_base {
  include profile::docker
  include profile::zfs::docker
}
