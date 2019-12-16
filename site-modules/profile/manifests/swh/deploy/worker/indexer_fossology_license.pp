# Deployment for swh-indexer-fossology-license

class profile::swh::deploy::worker::indexer_fossology_license {
  include ::profile::swh::deploy::indexer
  $packages = ['fossology-nomossa']
  package {$packages:
    ensure => 'present',
  }

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_fossology_license':
    ensure       => present,
    sentry_name  => 'indexer',
    require      => [
      Class['profile::swh::deploy::indexer'],
      Package[$packages],
    ],
  }
}
