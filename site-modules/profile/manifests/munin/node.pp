# Purge the munin node configuration
class profile::munin::node {
  service {'munin-node':
    ensure => stopped,
    enable => false,
  }
  -> package {['munin-node', 'munin-plugins-core', 'munin-plugins-extra']:
    ensure => purged,
  }
  -> file {['/etc/munin', '/var/lib/munin-node', '/var/cache/munin']:
    ensure  => absent,
    recurse => true,
    purge   => true,
    force   => true,
  }
}
