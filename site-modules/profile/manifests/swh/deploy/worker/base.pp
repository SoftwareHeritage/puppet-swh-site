# Base worker profile
class profile::swh::deploy::worker::base {

  include ::systemd::systemctl::daemon_reload

  $systemd_template_unit_name = 'swh-worker@.service'
  $systemd_unit_name = 'swh-worker.service'
  $systemd_slice_name = 'system-swh\x2dworker.slice'
  $systemd_generator = '/lib/systemd/system-generators/swh-worker-generator'

  package {'python3-swh.scheduler':
    ensure => installed,
  }

  ::systemd::unit_file {$systemd_template_unit_name:
    ensure => 'present',
    source => "puppet:///modules/profile/swh/deploy/worker/${systemd_template_unit_name}",
  }

  ::systemd::unit_file {$systemd_unit_name:
    ensure => 'present',
    source => "puppet:///modules/profile/swh/deploy/worker/${systemd_unit_name}",
  } ~> service {'swh-worker':
      ensure => running,
      enable => true,
  }

  ::systemd::unit_file {$systemd_slice_name:
    ensure => 'present',
    source => "puppet:///modules/profile/swh/deploy/worker/${systemd_slice_name}",
  }

  file {$systemd_generator:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/swh/deploy/worker/swh-worker-generator',
    notify => Class['systemd::systemctl::daemon_reload'],
  }

}
