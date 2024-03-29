# Deploy an instance of a rpc service

define profile::swh::deploy::rpc_server (
  String $executable,
  String $instance_name = $name,
  String $config_key = $name,
  String $gunicorn_config_base_module = 'swh.core.api.gunicorn_config',
  String $http_check_string = "SWH ${capitalize($name)} API server",
  Enum['sync', 'async'] $worker = 'sync',
) {
  include ::profile::nginx

  $conf_file = lookup("swh::deploy::${config_key}::conf_file")
  $user = lookup("swh::deploy::${config_key}::user")
  $group = lookup("swh::deploy::${config_key}::group")

  $service_name = "swh-${instance_name}"
  $gunicorn_service_name = "gunicorn-${service_name}"
  $gunicorn_unix_socket = "unix:/run/gunicorn/${service_name}/gunicorn.sock"

  $backend_listen_host = lookup("swh::deploy::${config_key}::backend::listen::host")
  $backend_listen_port = lookup("swh::deploy::${config_key}::backend::listen::port")
  $nginx_server_names = lookup("swh::deploy::${config_key}::backend::server_names")

  $backend_workers = lookup("swh::deploy::${config_key}::backend::workers")
  $backend_http_keepalive = lookup("swh::deploy::${config_key}::backend::http_keepalive")
  $backend_http_timeout = lookup("swh::deploy::${config_key}::backend::http_timeout")
  $backend_reload_mercy = lookup("swh::deploy::${config_key}::backend::reload_mercy")
  $backend_max_requests = lookup("swh::deploy::${config_key}::backend::max_requests")
  $backend_max_requests_jitter = lookup("swh::deploy::${config_key}::backend::max_requests_jitter")

  $instance_config = lookup("swh::deploy::${config_key}::config")

  $gunicorn_statsd_host = lookup('gunicorn::statsd::host')

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
    members               => {
      "gunicorn-${instance_name}" => {
        server => $gunicorn_unix_socket,
      },
    },
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
    proxy_read_timeout   => "${backend_http_timeout}s",
    format_log           => "combined if=\$error_status",
  }

  $sentry_dsn = lookup("swh::deploy::${config_key}::sentry_dsn", Optional[String], 'first', undef)
  $sentry_environment = lookup("swh::deploy::${config_key}::sentry_environment", Optional[String], 'first', undef)
  $sentry_swh_package = lookup("swh::deploy::${config_key}::sentry_swh_package", Optional[String], 'first', undef)

  ::gunicorn::instance {$service_name:
    ensure             => enabled,
    user               => $user,
    group              => $group,
    executable         => $executable,
    config_base_module => $gunicorn_config_base_module,
    environment        => {
      'SWH_CONFIG_FILENAME'    => $conf_file,
      'SWH_LOG_TARGET'         => 'journal',
      'SWH_SENTRY_DSN'         => $sentry_dsn,
      'SWH_SENTRY_ENVIRONMENT' => $sentry_environment,
      'SWH_MAIN_PACKAGE'       => $sentry_swh_package,
    },
    settings           => {
      bind                => $gunicorn_unix_socket,
      workers             => $backend_workers,
      worker_class        => $gunicorn_worker_class,
      timeout             => $backend_http_timeout,
      graceful_timeout    => $backend_reload_mercy,
      keepalive           => $backend_http_keepalive,
      max_requests        => $backend_max_requests,
      max_requests_jitter => $backend_max_requests_jitter,
      statsd_host         => $gunicorn_statsd_host,
      statsd_prefix       => $service_name,
    },
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  if $backend_listen_host == '0.0.0.0' {
    # It's not possible to directly test with the backend_listen_host in this case
    # so we fall back to localhost
    $local_check_address = '127.0.0.1'
  } else {
    $local_check_address = $backend_listen_host
  }

  @@::icinga2::object::service {"swh-${instance_name} api (local on ${::fqdn})":
    service_name     => "swh-${instance_name} api (localhost)",
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => $local_check_address,
      http_vhost   => $local_check_address,
      http_port    => $backend_listen_port,
      http_uri     => '/',
      http_header  => ['Accept: application/json'],
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
        http_vhost  => $::swh_hostname['internal_fqdn'],
        http_port   => $backend_listen_port,
        http_uri    => '/',
        http_header => ['Accept: application/json'],
        http_string => $http_check_string,
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
