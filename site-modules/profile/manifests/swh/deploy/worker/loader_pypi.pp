# Deployment for swh-loader-pypi
class profile::swh::deploy::worker::loader_pypi {
  $private_tmp = lookup('swh::deploy::worker::loader_pypi::private_tmp')

  $packages = ['python3-swh.loader.pypi']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_pypi':
    ensure       => present,
    private_tmp  => $private_tmp,
    sentry_name  => 'loader_core',
    require      => [
      Package[$packages],
    ],
  }
}
