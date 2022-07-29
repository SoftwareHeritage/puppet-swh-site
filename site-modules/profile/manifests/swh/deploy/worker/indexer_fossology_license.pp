# Deployment for indexer fossology-license
class profile::swh::deploy::worker::indexer_fossology_license {
  include ::profile::swh::deploy::indexer
  $packages = ['fossology-nomossa']
  package {$packages:
    ensure  => 'present',
    require => Apt::Source['softwareheritage'],
  }

  # Clean up previous indexer service implementation
  ::profile::swh::deploy::worker::instance {'indexer_fossology_license':
    ensure => absent,
  }

  Package[$::profile::swh::deploy::base_indexer::packages]
  ~> ::profile::swh::deploy::indexer_journal_client {'content_fossology_license':
    ensure      => present,
    sentry_name => $::profile::swh::deploy::base_indexer::sentry_name,
    require     => [
      Package[$::profile::swh::deploy::base_indexer::packages],
      Package[$packages::profile::swh::deploy::base_indexer::packages],
      Class['profile::swh::deploy::indexer']
    ],
  }

}
