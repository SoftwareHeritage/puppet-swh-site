# Ceph Monitor profile
class profile::ceph::mon {
  include profile::ceph::base

  $mon_secret = lookup('ceph::secrets::mon')
  $mgr_secret = lookup('ceph::secrets::mgr')

  $client_keys = lookup('ceph::keys')

  ::ceph::mon {$::hostname:
    key => $mon_secret,
  }

  ::ceph::mgr {$::hostname:
    key        => $mgr_secret,
    inject_key => true,
  }

  ::Ceph::Key {
    inject => true,
    inject_as_id => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
  }

  each($client_keys) |$name, $data| {
    ::ceph::key {"client.${name}":
      * => $data,
    }
  }
}
