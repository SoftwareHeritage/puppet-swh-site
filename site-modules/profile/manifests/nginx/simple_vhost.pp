# Deploy a simple nginx vhost
define profile::nginx::simple_vhost (
  Array[String] $server_names = [$::swh_hostname['internal_fqdn']],
  String $www_root = '/var/www/html',
  Stdlib::Port $http_port = 80,
  String $http_host = '0.0.0.0',
  String $http_check_string = 'Welcome to nginx',
  Hash $nginx_params = {},
) {
  # Default server on listen_port: return 444 for wrong domain name
  create_resources(
    'nginx::resource::server', {
      "nginx-default-${http_host}-${http_port}" => {
        ensure            => present,
        listen_ip         => $http_host,
        listen_port       => $http_port,
        listen_options    => 'default_server',
        maintenance       => true,
        maintenance_value => 'return 444',
      },
    })

  # actual server
  ::nginx::resource::server {"nginx-simple_vhost-${name}":
    ensure      => present,
    listen_ip   => $http_host,
    listen_port => $http_port,
    server_name => $server_names,
    www_root    => $www_root,
    *           => $nginx_params,
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_checks_hostname = lookup('icinga2::exported_checks::hostname')

  if $http_host == '0.0.0.0' {
    # It's not possible to directly test with the backend_listen_host in this case
    # so we fall back to localhost
    $local_check_address = '127.0.0.1'
  } else {
    $local_check_address = $http_host
  }

  ::icinga2::object::service {"Nginx simple vhost ${name} (local on ${::fqdn})":
    service_name     => "nginx ${name} (localhost)",
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => $local_check_address,
      http_vhost   => $server_names[0],
      http_port    => $http_port,
      http_uri     => '/',
      http_string  => $http_check_string,
    },
    target           => $icinga_checks_file,
    export_to        => [$icinga_checks_hostname]
  }

  if $http_host != '127.0.0.1' {
    ::icinga2::object::service {"Nginx simple vhost ${name} (remote on ${::fqdn})":
      service_name     => "nginx ${name} (remote)",
      import           => ['generic-service'],
      host_name        => $::fqdn,
      check_command    => 'http',
      command_endpoint => $::fqdn,
      vars             => {
        http_address => $http_host,
        http_vhost   => $server_names[0],
        http_port    => $http_port,
        http_uri     => '/',
        http_string  => $http_check_string,
      },
      target           => $icinga_checks_file,
      export_to        => [$icinga_checks_hostname]
    }
  }
}
