class role::swh_ceph_mon inherits role::swh_ceph {
  include profile::ceph::mon
}
