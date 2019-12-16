# Deployment for loader-archive
class profile::swh::deploy::worker::loader_archive {
  include ::profile::swh::deploy::worker::loader_package

  $private_tmp = lookup('swh::deploy::worker::loader_archive::private_tmp')

  # Extra dependencies to improve the tarball support
  package {'lzip':
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_archive':
    ensure       => present,
    private_tmp  => $private_tmp,
    sentry_name  => 'loader_core',
    require      => [
      Package[$packages],
      Package['lzip'],
    ],
  }
}
