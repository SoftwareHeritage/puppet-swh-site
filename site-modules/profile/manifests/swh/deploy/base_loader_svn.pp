# Svn Loader base configuration
class profile::swh::deploy::base_loader_svn {
  include ::profile::swh::deploy::loader

  $packages = ['python3-swh.loader.svn']

  package {$packages:
    ensure => 'present',
  }

}
