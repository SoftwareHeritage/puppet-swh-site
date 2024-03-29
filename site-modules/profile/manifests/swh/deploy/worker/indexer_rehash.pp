# Deployment for swh-indexer-rehash

class profile::swh::deploy::worker::indexer_rehash {
  include ::profile::swh::deploy::indexer

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_rehash':
    ensure      => 'stopped',
    sentry_name => 'indexer',
    require     => [
      Class['profile::swh::deploy::indexer']
    ],
  }
}
