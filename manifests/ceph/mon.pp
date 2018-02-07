# Ceph Monitor profile
class profile::ceph::mon {
  include profile::ceph::base

  $mon_key = hiera('ceph::key::mon')
  $mgr_key = hiera('ceph::key::mgr')
  $admin_key = hiera('ceph::key::admin')
  $bootstrap_osd_key = hiera('ceph::key::bootstrap_osd')

  ::ceph::mon {$::hostname:
    key => $mon_key,
  }

  ::ceph::mgr {$::hostname:
    key => $mgr_key,
  }

  ::Ceph::Key {
    inject => true,
    inject_as_id => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
  }

  ::ceph::key {'client.admin':
    secret  => $admin_key,
    cap_mon => 'allow *',
    cap_osd => 'allow *',
    cap_mds => 'allow',
  }

  ::ceph::key {'client.bootstrap-osd':
    secret  => $bootstrap_osd_key,
    cap_mon => 'allow profile bootstrap-osd',
  }
}
