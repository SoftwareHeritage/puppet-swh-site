# Deployment for swh-indexer-origin-intrinsic-metadata
class profile::swh::deploy::worker::indexer_origin_intrinsic_metadata {
  include ::profile::swh::deploy::indexer

  # Remove deprecated service
  ::profile::swh::deploy::worker::instance {'indexer_origin_intrinsic_metadata':
    ensure => absent,
  }

  include ::profile::swh::deploy::indexer_journal_client
}
