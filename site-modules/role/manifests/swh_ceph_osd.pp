class role::swh_ceph_osd inherits role::swh_ceph {
  include profile::ceph::osd
}
