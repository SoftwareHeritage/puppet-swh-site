# Deployment for loader-debian
class profile::swh::deploy::worker::loader_debian {
  include ::profile::swh::deploy::worker::loader_package

  package {'dpkg-dev':
    ensure => 'present',
  }

  $private_tmp = lookup('swh::deploy::worker::loader_debian::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_debian':
    ensure      => present,
    sentry_name => 'loader_core',
    private_tmp => $private_tmp,
    require     => [
      Package[$packages],
      Package['dpkg-dev'],
    ],
  }
}
