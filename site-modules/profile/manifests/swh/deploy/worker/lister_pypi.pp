# Deployment for swh-lister-pypi
class profile::swh::deploy::worker::lister_pypi {
  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_pypi':
    ensure       => present,
    require      => [
      Package['python3-swh.lister'],
    ],
  }
}
