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

  # install services from templates
  $services = [ {  # this matches the current status
    'name' => 'swhgraphshm',
    'status'  => 'stopped',
    'enable' => false,
  }, {
    'name' => 'swhgraphdev',
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

  $backend_listen_host = lookup("swh::deploy::graph::backend::listen::host")
  $backend_listen_port = lookup("swh::deploy::graph::backend::listen::port")

  $http_check_string = "graph API server"
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  # swhgraphdev.service exposes the main graph server.
  # Ensure the port is working ok through icinga checks
  @@::icinga2::object::service {"swh-graph api (local on ${::fqdn})":
    service_name     => "swh-graph api (localhost)",
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
    @@::icinga2::object::service {"swh-graph api (remote on ${::fqdn})":
      service_name  => "swh-graph api (remote)",
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
