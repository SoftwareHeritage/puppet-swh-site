# Deployment for indexer mimetype
class profile::swh::deploy::worker::indexer_content_mimetype {
  include ::profile::swh::deploy::indexer

  ::profile::swh::deploy::worker::instance {'indexer_content_mimetype':
    ensure => absent,
  }

  Package[$::profile::swh::deploy::base_indexer::packages]
  ~> ::profile::swh::deploy::indexer_journal_client {'mimetype':
    ensure      => present,
    sentry_name => $::profile::swh::deploy::base_indexer::sentry_name,
    require     => [
      Package[$::profile::swh::deploy::base_indexer::packages],
      Class['profile::swh::deploy::indexer']
    ],
  }

}
