# Deploy an instance of a rpc service

define profile::swh::deploy::rpc_server (
  String $executable,
  String $instance_name = $name,
  String $http_check_string = "SWH ${capitalize($name)} API server",
  Enum['sync', 'async'] $worker = 'sync',
) {
  include ::profile::nginx

  $conf_file = hiera("swh::deploy::${instance_name}::conf_file")
  $user = hiera("swh::deploy::${instance_name}::user")
  $group = hiera("swh::deploy::${instance_name}::group")

  $service_name = "swh-${instance_name}"
  $gunicorn_service_name = "gunicorn-${service_name}"
  $gunicorn_unix_socket = "unix:/run/gunicorn/${service_name}/gunicorn.sock"

  $backend_listen_host = hiera("swh::deploy::${instance_name}::backend::listen::host")
  $backend_listen_port = hiera("swh::deploy::${instance_name}::backend::listen::port")
  $nginx_server_names = hiera("swh::deploy::${instance_name}::backend::server_names")

  $backend_workers = hiera("swh::deploy::${instance_name}::backend::workers")
  $backend_http_keepalive = hiera("swh::deploy::${instance_name}::backend::http_keepalive")
  $backend_http_timeout = hiera("swh::deploy::${instance_name}::backend::http_timeout")
  $backend_reload_mercy = hiera("swh::deploy::${instance_name}::backend::reload_mercy")
  $backend_max_requests = hiera("swh::deploy::${instance_name}::backend::max_requests")
  $backend_max_requests_jitter = hiera("swh::deploy::${instance_name}::backend::max_requests_jitter")

  $instance_config = hiera("swh::deploy::${instance_name}::config")

  include ::gunicorn

  case $worker {
    'sync': {
      $gunicorn_worker_class = 'sync'
      $nginx_proxy_buffering = 'on'
    }
    'async': {
      $gunicorn_worker_class = 'aiohttp.worker.GunicornWebWorker'
      $nginx_proxy_buffering = 'off'
    }
    default: {
      fail("Worker class ${worker} is unsupported by this module.")
    }
  }

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @instance_config.to_yaml %>\n"),
    notify  => Service["gunicorn-swh-${instance_name}"],
  }

  ::nginx::resource::upstream {"swh-${instance_name}-gunicorn":
    upstream_fail_timeout => 0,
    members               => [
      $gunicorn_unix_socket,
    ],
  }

  # Default server on listen_port: return 444 for wrong domain name
  ::nginx::resource::server {"nginx-swh-${instance_name}-default":
    ensure            => present,
    listen_ip         => $backend_listen_host,
    listen_port       => $backend_listen_port,
    listen_options    => 'default_server',
    maintenance       => true,
    maintenance_value => 'return 444',
  }

  # actual server
  ::nginx::resource::server {"nginx-swh-${instance_name}":
    ensure               => present,
    listen_ip            => $backend_listen_host,
    listen_port          => $backend_listen_port,
    listen_options       => 'deferred',
    server_name          => $nginx_server_names,
    client_max_body_size => '4G',
    proxy                => "http://swh-${instance_name}-gunicorn",
    proxy_buffering      => $nginx_proxy_buffering,
  }

  ::gunicorn::instance {$service_name:
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => $executable,
    settings   => {
      bind                => $gunicorn_unix_socket,
      workers             => $backend_workers,
      worker_class        => $gunicorn_worker_class,
      timeout             => $backend_http_timeout,
      graceful_timeout    => $backend_reload_mercy,
      keepalive           => $backend_http_keepalive,
      max_requests        => $backend_max_requests,
      max_requests_jitter => $backend_max_requests_jitter,
    },
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"swh-${instance_name} api (localhost on ${::fqdn})":
    service_name     => "swh-${instance_name} api (localhost)",
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => '127.0.0.1',
      http_vhost   => '127.0.0.1',
      http_port    => $backend_listen_port,
      http_uri     => '/',
      http_string  => $http_check_string,
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  if $backend_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-${instance_name} api (remote on ${::fqdn})":
      service_name  => "swh-${instance_name} api (remote)",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_vhost  => $::fqdn,
        http_port   => $backend_listen_port,
        http_uri    => '/',
        http_string => 'SWH Vault API server',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
