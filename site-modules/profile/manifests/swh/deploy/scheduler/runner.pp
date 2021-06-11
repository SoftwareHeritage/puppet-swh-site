# Instance of scheduler runner
define profile::swh::deploy::scheduler::runner (
  $service_name       = $title,
  $user               = undef,
  $group              = undef,
  $packages           = undef,
  $config_file        = undef,
  $priority           = false,
  $sentry_dsn         = undef,
  $sentry_environment = undef,
  $sentry_swh_package = undef,
)
{
  $runner_log_level = lookup('swh::deploy::scheduler::runner::log_level')

  $task_types = lookup(
    "swh::deploy::scheduler::${service_name}::config::task-types",
    {default_value => []}
  )

  $runner_unit_name = "${service_name}.service"
  $runner_unit_template = "profile/swh/deploy/scheduler/swh-scheduler-runner.service.erb"

  $default_command = concat([
    "/usr/bin/swh",
    "--log-level ${runner_log_level}",
    "scheduler",
    "--config-file ${config_file}",
    "start-runner",
    "--period 10",
  ], $priority ? {
    true => [ "--with-priority" ],
    false => [],
  })

  # complete the command
  $runner_command = join(
    $task_types.reduce($default_command) | $command, $task_type | {
      $command + ["--task-type ${task_type}"]
    },
    " "
  )

  # Template uses variables
  # - $user
  # - $group
  # - $sentry_{dsn,environment,swh_package}
  # - $runner_command

  ::systemd::unit_file {$runner_unit_name:
    ensure  => present,
    content => template($runner_unit_template),
    notify  => Service[$service_name],
  }

  service {$service_name:
    ensure    => running,
    enable    => true,
    require   => [
      Package[$packages],
      File[$config_file],
      Systemd::Unit_File[$runner_unit_name],
    ],
    subscribe => Package[$packages],
  }

}
