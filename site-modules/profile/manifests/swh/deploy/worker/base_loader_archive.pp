# Deployment for loader-archive
class profile::swh::deploy::worker::base_loader_archive {
  include ::profile::swh::deploy::worker::loader_package

  # Extra dependencies to improve the tarball support
  package {'lzip':
    ensure => 'present',
  }
}
