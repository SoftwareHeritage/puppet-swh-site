# Purge the munin node configuration
class profile::munin::node {
  service {'munin-node':
    ensure => stopped,
    enable => false,
  }
  -> package {'munin-node':
    ensure => purged,
  }
  -> file {'/etc/munin':
    ensure  => absent,
    recurse => true,
    purge   => true,
    force   => true,
  }
}
