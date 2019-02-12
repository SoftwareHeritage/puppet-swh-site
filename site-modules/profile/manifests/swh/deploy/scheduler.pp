# Deployment of swh-scheduler related utilities
class profile::swh::deploy::scheduler {
  $config_file = lookup('swh::deploy::scheduler::conf_file')
  $user = lookup('swh::deploy::scheduler::user')
  $group = lookup('swh::deploy::scheduler::group')
  $config = lookup('swh::deploy::scheduler::config')

  $task_broker = lookup('swh::deploy::scheduler::task_broker')
  $task_packages = lookup('swh::deploy::scheduler::task_packages')
  $task_modules = lookup('swh::deploy::scheduler::task_modules')
  $task_backported_packages = lookup('swh::deploy::scheduler::backported_packages')

  $listener_service_name = 'swh-scheduler-listener'
  $listener_unit_name = "${listener_service_name}.service"
  $listener_unit_template = "profile/swh/deploy/scheduler/${listener_service_name}.service.erb"

  $runner_service_name = 'swh-scheduler-runner'
  $runner_unit_name = "${runner_service_name}.service"
  $runner_unit_template = "profile/swh/deploy/scheduler/${runner_service_name}.service.erb"

  $worker_conf_file = '/etc/softwareheritage/worker.ini'

  $packages = ['python3-swh.scheduler']
  $services = [$listener_service_name, $runner_service_name]

  $pinned_packages = $task_backported_packages[$::lsbdistcodename]
  if $pinned_packages {
    ::apt::pin {'swh-scheduler':
      explanation => 'Pin swh.scheduler dependencies to backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
    -> package {$task_packages:
      ensure => installed,
      notify => Service[$runner_service_name],
    }
  } else {
    package {$task_packages:
      ensure => installed,
      notify => Service[$runner_service_name],
    }
  }

  package {$packages:
    ensure => installed,
    notify => Service[$services],
  }

  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$services],
  }

  # Template uses variables
  #  - $task_broker
  #  - $task_modules
  #
  file {$worker_conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => template('profile/swh/deploy/scheduler/worker.ini.erb'),
    notify  => Service[$runner_service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit_file {$listener_unit_name:
    ensure  => present,
    content => template($listener_unit_template),
    notify  => Service[$listener_service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit_file {$runner_unit_name:
    ensure  => present,
    content => template($runner_unit_template),
    notify  => Service[$runner_service_name],
  }

  service {$runner_service_name:
    ensure  => running,
    enable  => true,
    require => [
      Package[$packages],
      Package[$task_packages],
      File[$config_file],
      File[$worker_conf_file],
      Systemd::Unit_File[$runner_unit_name],
    ],
  }

  service {$listener_service_name:
    ensure  => running,
    enable  => true,
    require => [
      Package[$packages],
      File[$config_file],
      File[$worker_conf_file],
      Systemd::Unit_File[$listener_unit_name],
    ],
  }

  # scheduler rpc server

  ::profile::swh::deploy::rpc_server {'scheduler':
    config_key => 'scheduler::remote',
    executable => 'swh.scheduler.api.server:run_from_webserver',
  }

  # task archival cron

  $archive_config_dir = lookup('swh::deploy::scheduler::archive::conf_dir')
  $archive_config_file = lookup('swh::deploy::scheduler::archive::conf_file')
  $archive_config = lookup('swh::deploy::scheduler::archive::config')

  file {$archive_config_dir:
    ensure => 'directory',
    owner  => $user,
    group  => 'swhscheduler',
    mode   => '0644',
  }

  file {$archive_config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @archive_config.to_yaml %>\n"),
    require      => [
      File[$archive_config_dir],
    ],
  }

  cron {'archive_completed_oneshot_and_disabled_recurring_tasks':
    ensure   => present,
    user     => $user,
    command  => "/usr/bin/python3 -m swh.scheduler.cli task archive",
    hour     => '*',
    minute   => fqdn_rand(60, 'archival_tasks_minute'),
    require  => [
      Package[$packages],
      File[$archive_config_file],
    ],
  }

}
