# Ceph OSD profile
class profile::ceph::osd {
  include profile::ceph::base

  $bootstrap_osd_key = hiera('ceph::key::bootstrap_osd')
  ::ceph::key {'client.bootstrap-osd':
    keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
    secret       => $bootstrap_osd_key,
  }

  ::ceph::osd {'/dev/sda':}
}
