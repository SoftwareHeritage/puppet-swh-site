# Runner for old-style tasks

class profile::swh::deploy::scheduler::runner {
  # The following variable is used by the runner_priority as well
  $service_args = ['start-runner', '--period', '10']

  profile::swh::deploy::scheduler::service {'runner':
    service_description => 'runner',
    service_args        => $service_args,
  }
}
