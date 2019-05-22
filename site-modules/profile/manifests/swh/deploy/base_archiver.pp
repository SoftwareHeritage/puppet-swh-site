# Archiver base configuration

class profile::swh::deploy::base_archiver {
  $packages = ['python3-swh.archiver']

  package {$packages:
    ensure => 'installed',
  }

}
