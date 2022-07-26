# Deployment for indexer origin-extrinsic-metadata
class profile::swh::deploy::worker::indexer_origin_extrinsic_metadata {
  include ::profile::swh::deploy::indexer

  ::profile::swh::deploy::indexer_journal_client {'extrinsic_metadata':
    ensure      => present,
    sentry_name => $::profile::swh::deploy::base_indexer::sentry_name,
    require     => [
      Package[$::profile::swh::deploy::base_indexer::packages],
      Class['profile::swh::deploy::indexer']
    ],
  }
}
