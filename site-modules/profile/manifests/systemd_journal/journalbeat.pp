# Journalbeat: a systemd journal collection beater for the ELK stack
class profile::systemd_journal::journalbeat {
  $package = 'journalbeat'
  $user = 'journalbeat'
  $group = 'nogroup'
  $homedir = '/var/lib/journalbeat'
  $configdir = '/etc/journalbeat'
  $configfile = "${configdir}/journalbeat.yml"
  $service = 'journalbeat'

  $logstash_hosts = lookup('systemd_journal::logstash_hosts')

  package {$package:
    ensure => present
  }

  user {$user:
    ensure     => present,
    gid        => $group,
    groups     => 'systemd-journal',
    home       => $homedir,
    managehome => true,
    system     => true,
  }

  # Uses variables
  #  - $user
  #  - $homedir
  #  - $configfile
  #
  ::systemd::unit_file {"${service}.service":
    ensure  => present,
    content => template('profile/systemd_journal/journalbeat/journalbeat.service.erb'),
  }
  ~> service {$service:
    ensure  => running,
    enable  => true,
    require => [
      Package[$package],
      File[$configfile],
    ],
  }

  file {$configdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Uses variables
  #  - $logstash_hosts
  #
  file {$configfile:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/systemd_journal/journalbeat/journalbeat.yml.erb'),
    notify  => [
      Service[$service],
    ],
  }

  ::apt::pin {'swh-journalbeat':
    explanation => 'Use journalbeat packages from Software Heritage',
    packages    => ['journalbeat'],
    originator  => 'softwareheritage',
    priority    => 990,
  }
}
