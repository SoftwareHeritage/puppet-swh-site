# Worker deployment
class profile::swh::deploy::worker {
  $instances = lookup('swh::deploy::worker::instances')

  each($instances) |$instance| {
    $classname = "::profile::swh::deploy::worker::${instance}"
    include $classname
  }
}
