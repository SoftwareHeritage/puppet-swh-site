# Worker deployment
class profile::swh::deploy::worker {
  $instances = lookup('swh::deploy::worker::instances')

  each($instances) |$instance| {
    $classname = "::profile::swh::deploy::worker::${instance}"
    include $classname
  }

  profile::cron::d {'cleanup-workers-tmp':
    command => 'find /tmp -depth -mindepth 3 -maxdepth 3 -type d -ctime +2 -exec rm -rf {} \+',
    target  => 'swh-worker',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand/2',
  }
}
