# Deployment of the swh.vault.api server

class profile::swh::deploy::vault {
  include ::profile::swh::deploy::base_vault

  $conf_directory = hiera('swh::deploy::vault::conf_directory')
  $conf_file = hiera('swh::deploy::vault::conf_file')
  $user = hiera('swh::deploy::vault::user')
  $group = hiera('swh::deploy::vault::group')

  $backend_listen_host = hiera('swh::deploy::vault::backend::listen::host')
  $backend_listen_port = hiera('swh::deploy::vault::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"

  $backend_workers = hiera('swh::deploy::vault::backend::workers')
  $backend_http_keepalive = hiera('swh::deploy::vault::backend::http_keepalive')
  $backend_http_timeout = hiera('swh::deploy::vault::backend::http_timeout')
  $backend_reload_mercy = hiera('swh::deploy::vault::backend::reload_mercy')
  $backend_max_requests = hiera('swh::deploy::vault::backend::max_requests')
  $backend_max_requests_jitter = hiera('swh::deploy::vault::backend::max_requests_jitter')

  $vault_config = hiera('swh::deploy::vault::config')

  include ::gunicorn

  Package['python3-swh.vault'] ~> Service['gunicorn-swh-vault']

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @vault_config.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-vault'],
  }

  ::gunicorn::instance {'swh-vault':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'swh.vault.api.server:make_app_from_configfile()',
    settings   => {
      bind                => $backend_listen_address,
      workers             => $backend_workers,
      worker_class        => 'aiohttp.worker.GunicornWebWorker',
      timeout             => $backend_http_timeout,
      graceful_timeout    => $backend_reload_mercy,
      keepalive           => $backend_http_keepalive,
      max_requests        => $backend_max_requests,
      max_requests_jitter => $backend_max_requests_jitter,
    }
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"swh-vault api (localhost on ${::fqdn})":
    service_name     => 'swh-vault api (localhost)',
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => '127.0.0.1',
      http_port    => $backend_listen_port,
      http_uri     => '/',
      http_string  => 'swh vault api server',
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  if $backend_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-vault api (remote on ${::fqdn})":
      service_name  => 'swh-vault api (remote)',
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_port   => $backend_listen_port,
        http_uri    => '/',
        http_string => 'swh vault api server',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
