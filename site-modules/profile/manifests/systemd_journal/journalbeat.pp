# Journalbeat: a systemd journal collection beater for the ELK stack
class profile::systemd_journal::journalbeat {
  $package = 'journalbeat'
  $configdir = '/etc/journalbeat'
  $configfile = "${configdir}/journalbeat.yml"
  $service = 'journalbeat'
  $default_elk_version = lookup('elastic::elk_version')
  $version = lookup('elastic::beat_version', { default_value => $default_elk_version })

  $logstash_hosts = lookup('systemd_journal::logstash_hosts')

  include ::profile::elastic::apt_config

  ::apt::pin {'journalbeat':
    explanation => 'Use the elk stack version for journalbeat',
    packages    => ['journalbeat'],
    version     => $version,
    priority    => 1001,
  }
  -> package {$package:
    ensure => $version,
  }
  -> file {'/var/lib/journalbeat':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  ::systemd::dropin_file { "${service}.conf":
    ensure  => present,
    unit    => "${service}.service",
    content => template('profile/systemd_journal/journalbeat/journalbeat.conf.erb'),
  }
  ~> service {$service:
    ensure    => running,
    enable    => true,
    require   => [
      Package[$package],
      File[$configfile],
      ::Systemd::Dropin_file["${service}.conf"],
    ],
    subscribe => [
      Package[$package],
      File[$configfile],
      ::Systemd::Dropin_file["${service}.conf"],
    ],
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
    require => [Package[$package]],
    notify  => [Service[$service]],
  }

  profile::cron::d {'logrotate-journal':
    target  => 'logrotate-journal',
    command => 'chronic sh -c "/usr/lib/nagios/plugins/swh/check_journal && journalctl --vacuum-time=\'7 days\'"',
    user    => 'root',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
  }
}
