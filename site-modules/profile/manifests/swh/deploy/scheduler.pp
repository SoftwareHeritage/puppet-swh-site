# Deployment of swh-scheduler related utilities
class profile::swh::deploy::scheduler {
  $config_dir = lookup('swh::deploy::scheduler::conf_dir')
  $config_file = lookup('swh::deploy::scheduler::conf_file')
  $user = lookup('swh::deploy::scheduler::user')
  $group = lookup('swh::deploy::scheduler::group')
  $config = lookup('swh::deploy::scheduler::config')

  $task_broker = lookup('swh::deploy::scheduler::task_broker')

  $packages = lookup('swh::deploy::scheduler::packages')

  include profile::swh::deploy::base_scheduler

  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    require => File[$config_dir],
  }

  # Service definitions
  $sentry_dsn = lookup('swh::deploy::scheduler::sentry_dsn', Optional[String], 'first', undef)
  $sentry_environment = lookup('swh::deploy::scheduler::sentry_environment', Optional[String], 'first', undef)
  $sentry_swh_package = lookup('swh::deploy::scheduler::sentry_swh_package', Optional[String], 'first', undef)

  $services_log_level = lookup('swh::deploy::scheduler::services::log_level')

  include profile::swh::deploy::scheduler::listener
  include profile::swh::deploy::scheduler::runner
  include profile::swh::deploy::scheduler::runner_priority

  include profile::swh::deploy::scheduler::schedule_recurrent

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

}
