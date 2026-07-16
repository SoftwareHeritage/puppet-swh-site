# Deployment for loader-nixguix
class profile::swh::deploy::worker::loader_nixguix {
  $private_tmp = lookup('swh::deploy::worker::loader_nixguix::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_nixguix':
    ensure      => present,
    private_tmp => $private_tmp,
    sentry_name => 'loader_core',
  }
}
