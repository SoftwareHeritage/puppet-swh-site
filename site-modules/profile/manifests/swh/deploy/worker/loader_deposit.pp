# Deployment for deposit's loader
class profile::swh::deploy::worker::loader_deposit {
  include ::profile::swh::deploy::worker::loader_package

  $private_tmp = lookup('swh::deploy::worker::loader_deposit::private_tmp')
  ::profile::swh::deploy::worker::instance {'loader_deposit':
    ensure      => 'present',
    sentry_name => 'loader_core',
    private_tmp => $private_tmp,
  }
}
