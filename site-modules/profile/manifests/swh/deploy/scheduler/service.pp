# Instance of scheduler service
define profile::swh::deploy::scheduler::service (
  $service_name        = "swh-scheduler-${title}",
  $service_description = undef,
  $service_args        = [],
)
{
  $user               = $profile::swh::deploy::scheduler::user
  $group              = $profile::swh::deploy::scheduler::group
  $packages           = $profile::swh::deploy::scheduler::packages
  $config_file        = $profile::swh::deploy::scheduler::config_file
  $sentry_dsn         = $profile::swh::deploy::scheduler::sentry_dsn
  $sentry_environment = $profile::swh::deploy::scheduler::sentry_environment
  $sentry_swh_package = $profile::swh::deploy::scheduler::sentry_swh_package

  $services_log_level = $profile::swh::deploy::scheduler::services_log_level

  $unit_name = "${service_name}.service"
  $unit_template = "profile/swh/deploy/scheduler/swh-scheduler.service.erb"

  $service_command = join([
    "/usr/bin/swh",
    "--log-level ${services_log_level}",
    "scheduler",
    "--config-file ${config_file}",
  ] + $service_args, " ")

  # Template uses variables
  # - $user
  # - $group
  # - $sentry_{dsn,environment,swh_package}
  # - $command
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template($unit_template),
  }
  ~> service {$service_name:
    ensure    => running,
    enable    => true,
  }

  [
    Package[$packages],
    File[$config_file],
  ] ~> Service[$service_name]
}
