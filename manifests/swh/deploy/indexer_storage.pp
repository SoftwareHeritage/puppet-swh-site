# Deployment of the swh.indexer.storage.api.server

class profile::swh::deploy::indexer_storage {
  include ::profile::swh::deploy::base_storage

  ::profile::swh::deploy::rpc_server {'indexer-storage':
    config_key        => 'indexer::storage',
    executable        => 'swh.indexer.storage.api.server:run_from_webserver',
    worker            => 'sync',
    http_check_string => 'SWH Indexer Storage API server',
  }
}
