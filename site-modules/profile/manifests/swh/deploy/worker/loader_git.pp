# Deployment for swh-loader-git (remote)
class profile::swh::deploy::worker::loader_git {
  include ::profile::swh::deploy::base_loader_git

  $load_metadata = lookup('swh::deploy::worker::loader_git::load_metadata')
  $packages = [$::profile::swh::deploy::base_loader_git::packages]

  if $load_metadata {
    $extra_config = lookup('swh::deploy::worker::loader_git::extra_config', {
      default_value => {}
    })
    $extra_packages = ['python3-swh.loader.metadata']
    ensure_packages($extra_packages)
    $all_packages = $packages + $extra_packages
  } else {
    $extra_config = {}
    $all_packages = $packages
  }

  ::profile::swh::deploy::worker::instance {'loader_git':
    ensure       => present,
    require      => Package[$all_packages],
    extra_config => $extra_config
  }
}
