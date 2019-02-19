# Deployment for swh-loader-debian
class profile::swh::deploy::worker::loader_debian {
  $packages = ['python3-swh.loader.debian']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_debian':
    ensure       => present,
    require      => [
      Package[$packages],
    ],
  }
}
