# Mercurial Loader base configuration
class profile::swh::deploy::base_loader_mercurial {
  include ::profile::swh::deploy::loader

  $packages = ['python3-swh.loader.mercurial']

  package {$packages:
    ensure => 'present',
  }

}
