# Disable rsyslog
class profile::rsyslog {
  service {'rsyslog':
    ensure => 'stopped',
    enable => 'false',
  }

  -> package {'rsyslog':
    ensure => 'purged',
  }
}
