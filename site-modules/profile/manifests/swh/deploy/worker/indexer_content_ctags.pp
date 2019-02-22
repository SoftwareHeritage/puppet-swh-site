# Deployment for swh-indexer-ctags

class profile::swh::deploy::worker::indexer_content_ctags {
  include ::profile::swh::deploy::indexer

  $packages = ['universal-ctags']
  package {$packages:
    ensure => 'present',
  }

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_content_ctags':
    ensure       => 'stopped',
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
      Package[$packages],
    ],
  }
}
