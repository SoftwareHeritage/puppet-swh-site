class role::swh_hypervisor_with_ceph inherits role::swh_hypervisor {
  include profile::ceph::mgr
}
