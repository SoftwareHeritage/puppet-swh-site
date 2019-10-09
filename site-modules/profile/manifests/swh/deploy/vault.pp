# Deployment of the swh.vault.api server

class profile::swh::deploy::vault {
  include ::profile::swh::deploy::base_vault
  Package['python3-swh.vault'] ~> Service['gunicorn-swh-vault']

  $user = lookup('swh::deploy::vault::user')
  $cache_directory = lookup('swh::deploy::vault::cache')
  file {$cache_directory:
    ensure => directory,
    owner  => $user,
    group  => 'swhdev',
    mode   => '0755',
  }

  ::profile::swh::deploy::rpc_server {'vault':
    executable => 'swh.vault.api.server:make_app_from_configfile()',
    worker     => 'async',
  }
}
