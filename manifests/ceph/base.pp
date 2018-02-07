# Base configuration for Ceph
class profile::ceph::base {
  $ceph_release = hiera('ceph::release')

  class {'::ceph::repo':
    release => $ceph_release,
  }
}
