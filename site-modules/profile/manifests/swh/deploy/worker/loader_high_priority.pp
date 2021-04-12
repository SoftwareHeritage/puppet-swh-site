# Deployment for high priority loader
class profile::swh::deploy::worker::loader_high_priority {
  include ::profile::swh::deploy::base_loader_git
  include ::profile::swh::deploy::base_loader_mercurial
  include ::profile::swh::deploy::base_loader_svn

  $packages = $::profile::swh::deploy::base_loader_git::packages + $::profile::swh::deploy::base_loader_mercurial::packages + $::profile::swh::deploy::base_loader_svn::packages

  ::profile::swh::deploy::worker::instance {'loader_high_priority':
    ensure       => present,
    require      => Package[$packages],
  }

}
