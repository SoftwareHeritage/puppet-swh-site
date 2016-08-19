# Deployment of swh-scheduler related utilities
class profile::swh::deploy::scheduler {
  $conf_file = hiera('swh::deploy::scheduler::conf_file')
  $user = hiera('swh::deploy::scheduler::user')
  $group = hiera('swh::deploy::scheduler::group')
  $database = hiera('swh::deploy::scheduler::database')

  include ::systemd

  $listener_service_name = 'swh-scheduler-listener'
  $listener_service_file = "/etc/systemd/system/${listener_service_name}.service"
  $listener_service_template = "profile/swh/deploy/scheduler/${listener_service_name}.service.erb"

  $runner_service_name = 'swh-scheduler-runner'
  $runner_service_file = "/etc/systemd/system/${runner_service_name}.service"
  $runner_service_template = "profile/swh/deploy/scheduler/${runner_service_name}.service.erb"

  $services = [$listener_service_name, $runner_service_name]

  package {'python3-swh.scheduler':
    ensure => latest,
    notify => Service[$services],
  }

  # Template uses variables
  #  - $database
  #
  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => template('profile/swh/deploy/scheduler/scheduler.ini.erb'),
    notify  => Service[$services],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  file {$listener_service_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($listener_service_template),
    notify  => [
      Exec['systemd-daemon-reload'],
      Service[$listener_service_name],
    ],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  file {$runner_service_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($runner_service_template),
    notify  => [
      Exec['systemd-daemon-reload'],
      Service[$runner_service_name],
    ],
  }

  service {$services:
    ensure => running,
    enable => true,
  }
}
