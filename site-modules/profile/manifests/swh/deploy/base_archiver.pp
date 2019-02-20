# Archiver base configuration

class profile::swh::deploy::base_archiver {
  include ::profile::swh::deploy::objstorage_cloud

  $packages = ['python3-swh.archiver']

  package {$packages:
    ensure => 'installed',
  }

}
