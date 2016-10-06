# Worker deployment
class profile::swh::deploy::worker {
  $instances = hiera_array('swh::deploy::worker::instances')

  if ('swh_loader_git' in $instances) {
    include ::profile::swh::deploy::worker::swh_loader_git
  }
}
