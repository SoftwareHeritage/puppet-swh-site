# Deployment for swh-indexer-origin-intrinsic-metadata

class profile::swh::deploy::worker::indexer_origin_intrinsic_metadata {
  include ::profile::swh::deploy::indexer

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_origin_intrinsic_metadata':
    ensure      => present,
    sentry_name => 'indexer',
    require     => [
      Class['profile::swh::deploy::indexer'],
    ],
  }
}
