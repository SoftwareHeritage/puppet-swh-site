# Deployment of the swh.vault.api server

class profile::swh::deploy::vault {
  include ::profile::swh::deploy::base_vault
  Package['python3-swh.vault'] ~> Service['gunicorn-swh-vault']

  ::profile::swh::deploy::rpc_instance {'vault':
    executable        => 'swh.vault.api.server:make_app_from_configfile()',
    worker            => 'async',
    http_check_string => 'SWH Vault API server',
  }
}
