# Deployment for swh-lister-github
class profile::swh::deploy::worker::lister_github {
  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_github':
    ensure       => present,
    require      => [
      Package['python3-swh.lister'],
    ],
  }
}
