# Deployment of the swh.storage.api server

class profile::swh::deploy::storage {
  include ::profile::swh::deploy::base_storage

  package {'python3-swh.storage':
    ensure => 'present',
  } ~> ::profile::swh::deploy::rpc_server {'storage':
    executable        => 'swh.storage.api.wsgi',
    worker            => 'sync',
    http_check_string => '<title>Software Heritage storage server</title>'
  }
}
