# Deployment for swh-indexer-mimetype

class profile::swh::deploy::worker::indexer_mimetype {
  include ::profile::swh::deploy::indexer

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_content_mimetype':
    ensure       => present,
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
    ],
  }
}
