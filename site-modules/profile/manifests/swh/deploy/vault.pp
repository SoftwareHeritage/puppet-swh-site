# Deployment of the swh.vault.api server

class profile::swh::deploy::vault {
  include ::profile::swh::deploy::base_vault
  Package['python3-swh.vault'] ~> Service['gunicorn-swh-vault']

  $group = lookup('swh::deploy::vault::group')
  $cache_directory = lookup('swh::deploy::vault::cache')
  file {$cache_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  ::profile::swh::deploy::rpc_server {'vault':
    executable => 'swh.vault.api.wsgi:app',
    worker     => 'async',
  }
}
