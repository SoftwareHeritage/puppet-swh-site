# Deployment of the swh.storage.api server

class profile::swh::deploy::storage {
  include ::profile::swh::deploy::base_storage

  ::profile::swh::deploy::rpc_server {'storage':
    executable => 'swh.storage.api.server:run_from_webserver',
    worker     => 'sync',
  }
}
