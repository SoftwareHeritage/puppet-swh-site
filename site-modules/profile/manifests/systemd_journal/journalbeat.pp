# Clean up journalbeat
class profile::systemd_journal::journalbeat {
  $package = 'journalbeat'
  $configdir = '/etc/journalbeat'
  $service = 'journalbeat'

  service {$service:
    ensure => stopped,
    enable => false,
  }
  ::apt::pin {'journalbeat':
    ensure => absent,
  }
  package {$package:
    ensure => absent,
  }
  file {'/var/lib/journalbeat':
    ensure  => absent,
    force   => true,
    recurse => true,
  }

  ::systemd::dropin_file { "${service}.conf":
    unit    => "${service}.service",
    ensure  => absent,
  }

  file {$configdir:
    ensure  => absent,
    force   => true,
    recurse => true,
  }
}
