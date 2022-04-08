# Deployment for swh-loader-npm
class profile::swh::deploy::worker::loader_npm {
  include ::profile::swh::deploy::worker::loader_package
  $private_tmp = lookup('swh::deploy::worker::loader_npm::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_npm':
    ensure      => present,
    private_tmp => $private_tmp,
    sentry_name => 'loader_core',
  }
}
