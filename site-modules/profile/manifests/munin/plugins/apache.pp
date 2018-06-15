# Munin plugins for Apache

class profile::munin::plugins::apache {
  munin::plugin { 'apache_volume':
    ensure => link,
  }
  munin::plugin { 'apache_accesses':
    ensure => link,
  }
  munin::plugin { 'apache_processes':
    ensure => link,
  }
}
