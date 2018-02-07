# Base configuration for Ceph
class profile::ceph::base {
  $ceph_release = hiera('ceph::release')

  $ceph_fsid = hiera('ceph::fsid')
  $ceph_mon_initial_members = join(hiera('ceph::mon_initial_members'), ',')
  $ceph_mon_host = join(hiera('ceph::mon_host'), ',')

  class {'::ceph::repo':
    release => $ceph_release,
  }

  class {'::ceph':
    fsid                => $ceph_fsid,
    mon_initial_members => $ceph_mon_initial_members,
    mon_host            => $ceph_mon_host,
  }
}
