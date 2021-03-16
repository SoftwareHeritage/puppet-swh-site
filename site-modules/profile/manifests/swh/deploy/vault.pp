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

  # Install vault end-to-end checks
  @@profile::icinga2::objects::e2e_checks_vault {"End-to-end Vault Test(s) in ${environement}":
    server_vault  => lookup('swh::deploy::vault::e2e::storage'),
    server_webapp => lookup('swh::deploy::vault::e2e::webapp'),
    environment   => $environment,
  }
}
