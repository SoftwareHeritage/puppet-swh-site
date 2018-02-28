# Deployment of the swh.vault.api server

class profile::swh::deploy::vault {
  include ::profile::swh::deploy::base_vault
  include ::profile::nginx

  $conf_file = hiera('swh::deploy::vault::conf_file')
  $user = hiera('swh::deploy::vault::user')
  $group = hiera('swh::deploy::vault::group')

  $service_name = 'swh-vault'
  $gunicorn_service_name = "gunicorn-${service_name}"
  $gunicorn_unix_socket = "unix:/run/gunicorn/${service_name}/gunicorn.sock"

  $backend_listen_host = hiera('swh::deploy::vault::backend::listen::host')
  $backend_listen_port = hiera('swh::deploy::vault::backend::listen::port')
  $nginx_server_names = hiera('swh::deploy::vault::server_names')

  $backend_workers = hiera('swh::deploy::vault::backend::workers')
  $backend_http_keepalive = hiera('swh::deploy::vault::backend::http_keepalive')
  $backend_http_timeout = hiera('swh::deploy::vault::backend::http_timeout')
  $backend_reload_mercy = hiera('swh::deploy::vault::backend::reload_mercy')
  $backend_max_requests = hiera('swh::deploy::vault::backend::max_requests')
  $backend_max_requests_jitter = hiera('swh::deploy::vault::backend::max_requests_jitter')

  $vault_config = hiera('swh::deploy::vault::config')

  include ::gunicorn

  Package['python3-swh.vault'] ~> Service['gunicorn-swh-vault']

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @vault_config.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-vault'],
  }

  ::nginx::resource::upstream {'swh-vault-gunicorn':
    members => [
      $gunicorn_unix_socket,
    ],
  }

  # Default server on listen_port: return 444 for wrong domain name
  ::nginx::resource::server {'nginx-swh-vault-default':
    ensure            => present,
    listen_ip         => $backend_listen_host,
    listen_port       => $backend_listen_port,
    listen_options    => 'default_server',
    maintenance       => true,
    maintenance_value => 'return 444',
  }

  # actual server
  ::nginx::resource::server {'nginx-swh-vault':
    ensure               => present,
    listen_ip            => $backend_listen_host,
    listen_port          => $backend_listen_port,
    listen_options       => 'deferred',
    server_name          => $nginx_server_names,
    client_max_body_size => '4G',
    raw_append           => ['keepalive 5;'],
    locations            => {
      '/' => {
        proxy => 'swh-vault-gunicorn',
      },
    },
  }

  ::gunicorn::instance {$service_name:
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'swh.vault.api.server:make_app_from_configfile()',
    settings   => {
      bind                => $gunicorn_unix_socket,
      workers             => $backend_workers,
      worker_class        => 'aiohttp.worker.GunicornWebWorker',
      timeout             => $backend_http_timeout,
      graceful_timeout    => $backend_reload_mercy,
      keepalive           => $backend_http_keepalive,
      max_requests        => $backend_max_requests,
      max_requests_jitter => $backend_max_requests_jitter,
    },
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
      http_string  => 'SWH Vault API server',
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
        http_string => 'SWH Vault API server',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
