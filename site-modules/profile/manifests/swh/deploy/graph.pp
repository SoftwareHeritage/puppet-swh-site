# Deployment of graph (checks for now)

# FIXME: Graph is currently managed manually and running through a venv. At some point,
# adapt here to also install fully the graph from that manifest
class profile::swh::deploy::graph {

  $packages = ['python3-venv']
  package {$packages:
    ensure => 'present',
  }

  $user = lookup('swh::deploy::graph::user')
  $group = lookup('swh::deploy::graph::group')

  $sentry_dsn = lookup('swh::deploy::graph::sentry_dsn', Optional[String], 'first', undef)
  $sentry_environment = lookup('swh::deploy::graph::sentry_environment', Optional[String], 'first', undef)
  $sentry_swh_package = lookup('swh::deploy::graph::sentry_swh_package', Optional[String], 'first', undef)

  $max_heap =  lookup('swh::deploy::graph::grpc::max_heap')

  $config_directory = lookup('swh::deploy::graph::conf_directory')

  $config_file = "${config_directory}/graph.yml"
  $config = { 'max_ram' => $max_heap }

  # install services from templates
  $services = [ {  # this matches the current status
    'name' => 'swh-graph-shm-mount',
    'status'  => 'running',
    'enable' => false,
  }, {
    'name' => 'swh-graph',
    'status'  => 'running',
    'enable' => true,
  }
  ]
  each($services) | $service | {
    $unit_name = "${service['name']}.service"

    # template uses:
    # $user
    # $group
    ::systemd::unit_file {$unit_name:
      ensure  => present,
      content => template("profile/swh/deploy/graph/${unit_name}.erb"),
      mode    => '0644',
    } ~> service {$service['name']:
      ensure => $service['status'],
      enable => $service['enable'],
    }
  }

  file {$config_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0650',
  }

  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service['swh-graph'],
  }

  $http_listen_host = lookup('swh::deploy::graph::http::listen::host')
  $http_listen_port = lookup('swh::deploy::graph::http::listen::port')

  $grpc_listen_host = lookup('swh::deploy::graph::grpc::listen::host')
  $grpc_listen_port = lookup('swh::deploy::graph::grpc::listen::port')

  $http_check_string = 'graph API server'
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  $http_local_check_address = $http_listen_host ? {
    '0.0.0.0' => '127.0.0.1',
    default   => $http_listen_host,
  }
  $grpc_local_check_address = $grpc_listen_host ? {
    '0.0.0.0' => '127.0.0.1',
    default   => $grpc_listen_host,
  }

  # swh-graph.service exposes the main graph server.
  # Ensure the port is working ok through icinga checks
  @@::icinga2::object::service {"swh-graph http api (local on ${::fqdn})":
    service_name     => 'swh-graph http api (localhost)',
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => $http_local_check_address,
      http_vhost   => $http_local_check_address,
      http_port    => $http_listen_port,
      http_uri     => '/',
      http_header  => ['Accept: application/html'],
      http_string  => $http_check_string,
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  @@::icinga2::object::service {"swh-graph grpc api (local on ${::fqdn})":
    service_name     => 'swh-graph grpc api (localhost)',
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'tcp',
    command_endpoint => $::fqdn,
    vars             => {
      tcp_port    => $grpc_listen_port,
      tcp_address => $grpc_local_check_address,
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  if $http_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-graph http api (remote on ${::fqdn})":
      service_name  => 'swh-graph http api (remote)',
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_vhost  => $::swh_hostname['internal_fqdn'],
        http_port   => $http_listen_port,
        http_uri    => '/',
        http_header => ['Accept: application/html'],
        http_string => $http_check_string,
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
  if $grpc_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-graph grpc api (remote on ${::fqdn})":
      service_name     => 'swh-graph grpc api (remote)',
      import           => ['generic-service'],
      host_name        => $::fqdn,
      check_command    => 'tcp',
      vars             => {
        tcp_port    => $grpc_listen_port,
        tcp_address => $::swh_hostname['internal_fqdn'],
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }

}
