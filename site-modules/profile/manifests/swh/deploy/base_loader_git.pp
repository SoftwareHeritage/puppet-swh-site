# Git Loader base configuration
class profile::swh::deploy::base_loader_git {
  include ::profile::swh::deploy::loader

  $load_metadata = lookup('swh::deploy::worker::loader_git::load_metadata')
  $packages = ['python3-swh.loader.git']

  if $load_metadata {
    $extra_config = lookup('swh::deploy::worker::loader_git::extra_config', {
      default_value => {}
    })
    $extra_packages = ['python3-swh.loader.metadata']
    ensure_packages($extra_packages)
    $all_packages = $packages + $extra_packages
  } else {
    $extra_config = {}
  }

  ensure_packages($packages)

}
