# Deployment for swh-indexer-language

class profile::swh::deploy::worker::indexer_language {
  include ::profile::swh::deploy::indexer
  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_content_language':
    ensure       => 'stopped',
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
    ],
  }
}
