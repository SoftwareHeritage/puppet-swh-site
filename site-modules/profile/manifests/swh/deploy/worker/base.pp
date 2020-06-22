# Base worker profile
class profile::swh::deploy::worker::base {

  $systemd_template_unit_name = 'swh-worker@.service'
  $systemd_unit_name = 'swh-worker.service'
  $systemd_slice_name = 'system-swh\x2dworker.slice'

  $celery_hostname = $swh_hostname['internal_fqdn']

  package {'python3-swh.scheduler':
    ensure => installed,
  }

  ::systemd::unit_file {$systemd_template_unit_name:
    ensure => 'present',
    content => template("profile/swh/deploy/worker/${systemd_template_unit_name}.erb"),
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

  profile::cron::d {'cleanup-workers-tmp':
    command => 'find /tmp -depth -mindepth 3 -maxdepth 3 -type d -ctime +2 -exec rm -rf {} \+',
    target  => 'swh-worker',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand/2',
  }

  file {'/usr/local/sbin/swh-worker-ping-restart':
    source => 'puppet:///profile/swh/deploy/worker/swh-worker-ping-restart',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
