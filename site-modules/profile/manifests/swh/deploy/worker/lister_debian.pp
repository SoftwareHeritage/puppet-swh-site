# Deployment for swh-lister-debian
class profile::swh::deploy::worker::lister_debian {
  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_debian':
    ensure       => present,
    require      => [
      Package['python3-swh.lister'],
    ],
  }
}
