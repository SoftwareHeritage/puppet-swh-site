# Deployment of swh-scheduler related utilities
class profile::swh::deploy::scheduler {
  $config_dir = lookup('swh::deploy::scheduler::conf_dir')
  $config_file = lookup('swh::deploy::scheduler::conf_file')
  $user = lookup('swh::deploy::scheduler::user')
  $group = lookup('swh::deploy::scheduler::group')
  $config = lookup('swh::deploy::scheduler::config')

  $listener_log_level = lookup('swh::deploy::scheduler::listener::log_level')
  $runner_log_level = lookup('swh::deploy::scheduler::runner::log_level')

  $task_broker = lookup('swh::deploy::scheduler::task_broker')

  $sentry_dsn = lookup('swh::deploy::scheduler::sentry_dsn', Optional[String], 'first', undef)
  $sentry_environment = lookup('swh::deploy::scheduler::sentry_environment', Optional[String], 'first', undef)
  $sentry_swh_package = lookup('swh::deploy::scheduler::sentry_swh_package', Optional[String], 'first', undef)

  $listener_service_name = 'swh-scheduler-listener'
  $listener_unit_name = "${listener_service_name}.service"
  $listener_unit_template = "profile/swh/deploy/scheduler/${listener_service_name}.service.erb"

  $runner_service_name = 'swh-scheduler-runner'
  $runner_unit_name = "${runner_service_name}.service"
  $runner_unit_template = "profile/swh/deploy/scheduler/${runner_service_name}.service.erb"

  $packages = lookup('swh::deploy::scheduler::packages')
  $services = [$listener_service_name, $runner_service_name]

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

  # purge legacy config file
  $to_purge_legacy_files = [ '/etc/softwareheritage/scheduler.yml', '/etc/softwareheritage/backend']
  each($to_purge_legacy_files) | $to_purge| {
    file {$to_purge:
      ensure  => absent,
      recurse => true,
      force   => true,
    }
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
    ensure    => running,
    enable    => true,
    require   => [
      Package[$packages],
      File[$config_file],
      Systemd::Unit_File[$runner_unit_name],
    ],
    subscribe => Package[$packages],
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

  # scheduler rpc server

  ::profile::swh::deploy::rpc_server {'scheduler':
    config_key        => 'scheduler::remote',
    executable        => 'swh.scheduler.api.server:make_app_from_configfile()',
    http_check_string => 'Software Heritage scheduler RPC server',
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
