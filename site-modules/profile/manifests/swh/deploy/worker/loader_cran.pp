# Deployment for loader-cran
class profile::swh::deploy::worker::loader_cran {
  include ::profile::swh::deploy::worker::base_loader_archive

  $private_tmp = lookup('swh::deploy::worker::loader_cran::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_cran':
    ensure      => present,
    private_tmp => $private_tmp,
    sentry_name => 'loader_core',
    require     => Class['profile::swh::deploy::worker::base_loader_archive'],
  }
}
