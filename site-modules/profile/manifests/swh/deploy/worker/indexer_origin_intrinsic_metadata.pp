# Deployment for indexer origin-intrinsic-metadata
class profile::swh::deploy::worker::indexer_origin_intrinsic_metadata {
  include ::profile::swh::deploy::indexer

  ::profile::swh::deploy::indexer_journal_client {'intrinsic_metadata':
    ensure       => present,
    sentry_name  => $::profile::swh::deploy::base_indexer::sentry_name,
    require      => [
      Package[$::profile::swh::deploy::base_indexer::packages],
      Class['profile::swh::deploy::indexer']
    ],
  }
}
