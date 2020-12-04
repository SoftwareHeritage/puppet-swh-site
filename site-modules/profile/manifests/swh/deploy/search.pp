# Deployment of the swh.search.api server
class profile::swh::deploy::search {
  include ::profile::swh::deploy::base_search

  Package['python3-swh.search'] ~> Service['gunicorn-swh-search']

  ::profile::swh::deploy::rpc_server {'search':
    executable => 'swh.search.api.server:make_app_from_configfile()',
  }
}
