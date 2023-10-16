class role::rancher_node inherits role::swh_base {
  include profile::zfs::kubelet
  include profile::zfs::rancher
  include profile::mountpoints
  include profile::kubernetes
}
