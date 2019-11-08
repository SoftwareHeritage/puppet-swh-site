# Base loader package configuration
class profile::swh::deploy::loader_package {
  $packages = ['python3-swh.loader.core']

  package {$packages:
    ensure => 'present',
  }
}
