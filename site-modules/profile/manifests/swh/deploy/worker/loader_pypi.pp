# Deployment for swh-loader-pypi
class profile::swh::deploy::worker::loader_pypi {
  include ::profile::swh::deploy::worker::loader_package
  $private_tmp = lookup('swh::deploy::worker::loader_pypi::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_pypi':
    ensure      => present,
    private_tmp => $private_tmp,
    sentry_name => 'loader_core',
  }
}
