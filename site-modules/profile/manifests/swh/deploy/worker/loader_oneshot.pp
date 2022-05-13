# Deployment for oneshot loader
class profile::swh::deploy::worker::loader_oneshot {
  include ::profile::swh::deploy::base_loader_git
  include ::profile::swh::deploy::base_loader_mercurial
  include ::profile::swh::deploy::base_loader_svn

  $packages = $::profile::swh::deploy::base_loader_git::packages + $::profile::swh::deploy::base_loader_mercurial::packages + $::profile::swh::deploy::base_loader_svn::packages

  ::profile::swh::deploy::worker::instance {'loader_oneshot':
    ensure       => present,
    require      => Package[$packages],
    extra_config => $::profile::swh::deploy::base_loader_git::extra_config,
  }

}
