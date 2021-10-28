# Runner for priority tasks
class profile::swh::deploy::scheduler::runner_priority {
  $service_name = 'runner-priority'

  $task_types = lookup(
    "swh::deploy::scheduler::swh-scheduler-${service_name}::config::task_types",
    {default_value => []}
  )

  $priority_service_args = $profile::swh::deploy::scheduler::runner::service_args + ['--with-priority']

  # add task filter arguments
  $service_args = $task_types.reduce($priority_service_args) | $command, $task_type | {
      $command + ['--task-type', $task_type]
  }

  profile::swh::deploy::scheduler::service {$service_name:
    service_description => 'runner for high priority tasks',
    service_args        => $service_args,
  }
}
