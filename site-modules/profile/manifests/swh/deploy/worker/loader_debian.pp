# Deployment for loader-debian
class profile::swh::deploy::worker::loader_debian {
  include ::profile::swh::deploy::worker::loader_package

  package {'dpkg-dev':
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_debian':
    ensure       => present,
    require      => [
      Package[$packages],
      Package['dpkg-dev'],
    ],
  }
}
