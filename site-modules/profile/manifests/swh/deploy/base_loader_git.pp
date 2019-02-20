# Git Loader base configuration

class profile::swh::deploy::base_loader_git {
  include ::profile::swh::deploy::loader

  $packages = ['python3-swh.loader.git']

  package {$packages:
    ensure => 'present',
  }

}
