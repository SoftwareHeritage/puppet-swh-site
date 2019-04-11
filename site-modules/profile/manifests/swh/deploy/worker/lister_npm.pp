# Deployment for swh-lister-npm
class profile::swh::deploy::worker::lister_npm {
  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_npm':
    ensure       => present,
    require      => [
      Package['python3-swh.lister'],
    ],
  }
}
