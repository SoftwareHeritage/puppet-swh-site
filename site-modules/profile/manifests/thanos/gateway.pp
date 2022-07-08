# Thanos gateway services (historical metrics access)
class profile::thanos::gateway {
  include profile::thanos::base

  $service_name = 'thanos-gateway'
  $unit_name = "${service_name}.service"
  $port_http = lookup('thanos::gateway::port_http')
  $port_grpc = lookup('thanos::gateway::port_grpc')
  $internal_ip = ip_for_network(lookup('internal_network'))
  $grpc_address = "${internal_ip}:${port_grpc}"

  $objstore_config = lookup('thanos::objstore::config')
  $objstore_config_file = "${::profile::thanos::base::config_dir}/objstore.yml"
  $config_filepath = $::profile::thanos::base::config_filepath

  file {$objstore_config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'prometheus',
    mode    => '0640',
    content => inline_yaml($objstore_config),
    require => File[$::profile::thanos::base::config_dir],
  }

  $gateway_arguments = {
    'data-dir'     => '/var/lib/prometheus/metrics2',
    objstore       => {
      'config-file' => $objstore_config_file,
    },
    'http-address' => "${internal_ip}:${port_http}",
    'grpc-address' => $grpc_address,
  }

  # Template uses:
  # $gateway_arguments
  systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/thanos/gateway.service.erb'),
    require => Class['profile::thanos::base'],
    notify  => Service[$service_name]
  }

  service {$service_name:
    ensure  => 'running',
    enable  => true,
  }

  # gateway service grpc address pushed to query service configuration file to access
  # historical data
  ::profile::thanos::export_query_endpoint {"thanos-gateway-${::fqdn}":
    grpc_address => $grpc_address
  }
}
