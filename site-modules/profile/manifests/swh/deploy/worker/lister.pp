# Deployment for swh-lister-github
class profile::swh::deploy::worker::lister {
  $packages = ['python3-swh.lister']

  package {$packages:
    ensure => present,
  }

  ::profile::swh::deploy::worker::instance {'lister':
    ensure       => present,
    require      => [
      Package['python3-swh.lister'],
    ],
  }
}
