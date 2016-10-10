# Base worker profile
class profile::swh::deploy::worker::base {
  include ::systemd

  $systemd_template_unit_name = 'swh-worker@.service'
  $systemd_template_unit_file = "/etc/systemd/system/${systemd_template_unit_name}"
  $systemd_unit_name = 'swh-worker.service'
  $systemd_unit_file = "/etc/systemd/system/${systemd_unit_name}"
  $systemd_generator = '/lib/systemd/system-generators/swh-worker-generator'
  $config_directory = '/etc/softwareheritage/worker'

  package {'python3-swh.scheduler':
    ensure => installed,
  }

  file {$systemd_template_unit_file:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/profile/swh/deploy/worker/${systemd_template_unit_name}",
    notify => Exec['systemd-daemon-reload'],
  }

  file {$systemd_unit_file:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/profile/swh/deploy/worker/${systemd_unit_name}",
    notify => Exec['systemd-daemon-reload'],
  }

  file {$systemd_generator:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/swh/deploy/worker/swh-worker-generator',
    notify => Exec['systemd-daemon-reload'],
  }

  file {$config_directory:
    ensure  => 'directory',
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    purge   => true,
    recurse => true,
  }

  service {'swh-worker':
    ensure  => running,
    enable  => true,
    require => [
      Exec['systemd-daemon-reload'],
      File[$systemd_template_unit_file],
      File[$systemd_unit_file],
      File[$systemd_generator],
    ],
  }
}
