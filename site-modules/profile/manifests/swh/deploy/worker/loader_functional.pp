# Deployment for loader-functional
class profile::swh::deploy::worker::loader_functional {
  include ::profile::swh::deploy::worker::base_loader_archive

  $private_tmp = lookup('swh::deploy::worker::loader_functional::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_functional':
    ensure       => present,
    private_tmp  => $private_tmp,
    sentry_name  => 'loader_core',
  }
}
