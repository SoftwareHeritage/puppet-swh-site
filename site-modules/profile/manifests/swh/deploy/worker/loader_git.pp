# Deployment for swh-loader-git (remote)
class profile::swh::deploy::worker::loader_git {
  include ::profile::swh::deploy::base_loader_git

  ::profile::swh::deploy::worker::instance {'loader_git':
    ensure       => present,
    require      => Package[$::profile::swh::deploy::base_loader_git::packages],
    extra_config => $::profile::swh::deploy::base_loader_git::extra_config
  }
}
