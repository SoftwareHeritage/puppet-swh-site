# Deployment for swh-lister-gitlab
class profile::swh::deploy::worker::lister_gitlab {
  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_gitlab':
    ensure       => present,
    require      => [
      Package['python3-swh.lister'],
    ],
  }
}
