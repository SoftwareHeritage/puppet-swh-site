# Journalbeat: a systemd journal collection beater for the ELK stack
class profile::systemd_journal::journalbeat {
  $package = 'journalbeat'
  $user = 'journalbeat'
  $group = 'nogroup'
  $homedir = '/var/lib/journalbeat'
  $configdir = '/etc/journalbeat'
  $configfile = "${configdir}/journalbeat.yml"
  $service = 'journalbeat'
  $servicefile = "/etc/systemd/system/${service}.service"

  $logstash_hosts = hiera('systemd_journal::logstash_hosts')

  include ::systemd

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
  file {$servicefile:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/systemd_journal/journalbeat/journalbeat.service.erb'),
    require => Package[$package],
    notify  => [
      Exec['systemd-daemon-reload'],
      Service[$service],
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
      Exec['systemd-daemon-reload'],
      Service[$service],
    ],
  }

  service {$service:
    ensure  => running,
    enable  => true,
    require => [
      File[$servicefile],
      File[$configfile],
      Exec['systemd-daemon-reload'],
    ],
  }
}
