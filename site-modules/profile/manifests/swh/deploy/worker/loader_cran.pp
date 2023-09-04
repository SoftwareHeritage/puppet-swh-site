# Deployment for loader-cran
class profile::swh::deploy::worker::loader_cran {
  include ::profile::swh::deploy::worker::base_loader_archive

  ::profile::swh::deploy::worker::instance {'loader_cran':
    sentry_name => 'loader_core',
    ensure      => absent,
  }
}
