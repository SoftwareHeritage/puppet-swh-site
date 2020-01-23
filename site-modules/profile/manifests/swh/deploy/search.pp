# Deployment of the swh.search.api server
class profile::swh::deploy::search {
  $packages = ['python3-swh.search']

  package {$packages:
    ensure => 'present',
  } ~> Service['gunicorn-swh-search']

  ::profile::swh::deploy::rpc_server {'search':
    executable => 'swh.search.api.server:make_app_from_configfile()',
  }
}
