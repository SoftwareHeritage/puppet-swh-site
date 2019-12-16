# Deployment of swh-scheduler related utilities
class profile::swh::deploy::scheduler {
  $config_file = lookup('swh::deploy::scheduler::conf_file')
  $user = lookup('swh::deploy::scheduler::user')
  $group = lookup('swh::deploy::scheduler::group')
  $config = lookup('swh::deploy::scheduler::config')

  $listener_log_level = lookup('swh::deploy::scheduler::listener::log_level')
  $runner_log_level = lookup('swh::deploy::scheduler::runner::log_level')

  $task_broker = lookup('swh::deploy::scheduler::task_broker')

  $sentry_dsn = lookup('swh::deploy::scheduler::sentry_dsn', Optional[String], 'first', undef)

  $listener_service_name = 'swh-scheduler-listener'
  $listener_unit_name = "${listener_service_name}.service"
  $listener_unit_template = "profile/swh/deploy/scheduler/${listener_service_name}.service.erb"

  $runner_service_name = 'swh-scheduler-runner'
  $runner_unit_name = "${runner_service_name}.service"
  $runner_unit_template = "profile/swh/deploy/scheduler/${runner_service_name}.service.erb"

  $packages = ['python3-swh.scheduler']
  $services = [$listener_service_name, $runner_service_name]

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

  # purge legacy config file
  $worker_conf_file = '/etc/softwareheritage/worker.ini'
  file {$worker_conf_file:
    ensure  => absent,
  }

  # Template uses variables
  #  - $user
  #  - $group
  #  - $sentry_dsn
  #
  ::systemd::unit_file {$listener_unit_name:
    ensure  => present,
    content => template($listener_unit_template),
    notify  => Service[$listener_service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #  - $sentry_dsn
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
      File[$config_file],
      Systemd::Unit_File[$runner_unit_name],
    ],
  }

  service {$listener_service_name:
    ensure  => running,
    enable  => true,
    require => [
      Package[$packages],
      File[$config_file],
      Systemd::Unit_File[$listener_unit_name],
    ],
  }

  # scheduler rpc server

  ::profile::swh::deploy::rpc_server {'scheduler':
    config_key => 'scheduler::remote',
    executable => 'swh.scheduler.api.server:make_app_from_configfile()',
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
    ensure   => absent,
    user     => $user,
    command  => "/usr/bin/swh scheduler --config-file ${archive_config_file} task archive",
    hour     => '*',
    minute   => fqdn_rand(60, 'archival_tasks_minute'),
    require  => [
      Package[$packages],
      File[$archive_config_file],
    ],
  }

}
