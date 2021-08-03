# Deployment of swh-scheduler related utilities
class profile::swh::deploy::scheduler {
  $config_dir = lookup('swh::deploy::scheduler::conf_dir')
  $config_file = lookup('swh::deploy::scheduler::conf_file')
  $user = lookup('swh::deploy::scheduler::user')
  $group = lookup('swh::deploy::scheduler::group')
  $config = lookup('swh::deploy::scheduler::config')

  $sentry_dsn = lookup('swh::deploy::scheduler::sentry_dsn', Optional[String], 'first', undef)
  $sentry_environment = lookup('swh::deploy::scheduler::sentry_environment', Optional[String], 'first', undef)
  $sentry_swh_package = lookup('swh::deploy::scheduler::sentry_swh_package', Optional[String], 'first', undef)

  $listener_log_level = lookup('swh::deploy::scheduler::listener::log_level')

  $task_broker = lookup('swh::deploy::scheduler::task_broker')

  $listener_service_name = 'swh-scheduler-listener'
  $listener_unit_name = "${listener_service_name}.service"
  $listener_unit_template = "profile/swh/deploy/scheduler/${listener_service_name}.service.erb"

  $runner_service_name = 'swh-scheduler-runner'
  $runner_priority_service_name = 'swh-scheduler-runner-priority'

  $packages = lookup('swh::deploy::scheduler::packages')
  $services = [
    $listener_service_name,
    $runner_service_name,
    $runner_priority_service_name,
  ]

  include profile::swh::deploy::base_scheduler

  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$services],
    require => File[$config_dir],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #  - $sentry_{dsn,environment,swh_package}
  #
  ::systemd::unit_file {$listener_unit_name:
    ensure  => present,
    content => template($listener_unit_template),
    notify  => Service[$listener_service_name],
  }

  service {$listener_service_name:
    ensure    => running,
    enable    => true,
    require   => [
      Package[$packages],
      File[$config_file],
      Systemd::Unit_File[$listener_unit_name],
    ],
    subscribe => Package[$packages],
  }

  ::profile::swh::deploy::scheduler::runner {$runner_service_name:
    user               => $user,
    group              => $group,
    packages           => $packages,
    config_file        => $config_file,
    sentry_dsn         => $sentry_dsn,
    sentry_environment => $sentry_environment,
    sentry_swh_package => $sentry_swh_package,
  }

  ::profile::swh::deploy::scheduler::runner {$runner_priority_service_name:
    user               => $user,
    group              => $group,
    packages           => $packages,
    config_file        => $config_file,
    sentry_dsn         => $sentry_dsn,
    sentry_environment => $sentry_environment,
    sentry_swh_package => $sentry_swh_package,
    priority           => true,
  }

  # scheduler rpc server

  ::profile::swh::deploy::rpc_server {'scheduler':
    config_key        => 'scheduler::remote',
    executable        => 'swh.scheduler.api.server:make_app_from_configfile()',
    http_check_string => 'Software Heritage scheduler RPC server',
  }

  # scheduler update metrics routine

  # Template uses variables
  #  - $user
  #  - $group
  #  - $config_file
  #
  $update_metrics_service_name = "swh-scheduler-update-metrics"
  $update_metrics_unit_template = "profile/swh/deploy/scheduler/${update_metrics_service_name}.service.erb"
  $update_metrics_timer_name = "${update_metrics_service_name}.timer"
  $update_metrics_timer_template = "profile/swh/deploy/scheduler/${update_metrics_timer_name}.erb"

  ::systemd::timer { $update_metrics_timer_name:
    timer_content    => template($update_metrics_timer_template),
    service_content  => template($update_metrics_unit_template),
    active           => true,
    enable           => true,
    require          => Package[$packages],
  }

  # task archival cron

  $archive_config_file = lookup('swh::deploy::scheduler::archive::conf_file')
  $archive_config = lookup('swh::deploy::scheduler::archive::config')

  file {$archive_config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @archive_config.to_yaml %>\n"),
    require => File[$config_dir],
  }

  cron {'archive_completed_oneshot_and_disabled_recurring_tasks':
    ensure => absent,
    user   => $user,
  }

  profile::cron::d {'scheduler_archive_tasks':
    user     => $user,
    command  => "/usr/bin/swh scheduler --config-file ${archive_config_file} task archive",
    monthday => '1',
    hour     => '0',
    minute   => '0',
    require  => [
      Package[$packages],
      File[$archive_config_file],
    ],
  }
}
