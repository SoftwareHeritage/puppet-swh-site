# Base configuration for Ceph
class profile::ceph::base {
  $ceph_release = lookup('ceph::release')

  $ceph_fsid = lookup('ceph::fsid')
  $ceph_mon_initial_members = join(lookup('ceph::mon_initial_members'), ',')
  $ceph_mon_host = join(lookup('ceph::mon_host'), ',')

  class {'::ceph::repo':
    release => $ceph_release,
  }

  class {'::ceph':
    fsid                => $ceph_fsid,
    mon_initial_members => $ceph_mon_initial_members,
    mon_host            => $ceph_mon_host,
  }
}
