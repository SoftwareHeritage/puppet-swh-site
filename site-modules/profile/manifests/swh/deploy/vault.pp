# Deployment of the swh.vault.api server

class profile::swh::deploy::vault {
  include ::profile::swh::deploy::base_vault
  Package['python3-swh.vault'] ~> Service['gunicorn-swh-vault']

  ::profile::swh::deploy::rpc_server {'vault':
    executable => 'swh.vault.api.wsgi:app',
    worker     => 'async',
  }
}
