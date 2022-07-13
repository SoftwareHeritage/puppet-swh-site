# Thanos gateway services (historical metrics access)
class profile::thanos::gateway {
  include profile::thanos::base
  include profile::thanos::tls_certificate

  $cert_paths = $::profile::thanos::tls_certificate::cert_paths

  $internal_ip = ip_for_network(lookup('internal_network'))

  $services = lookup('thanos::gateway::services')

  $azure_account = lookup('thanos::objstore::azure_account')
  $azure_account_key = lookup('thanos::objstore::azure_account_key')

  $config_dir = $::profile::thanos::base::config_dir
  $services.each | $dataset_name, $service | {
    $objstore_config = {
      "type"   => "AZURE",
      "config" => {
        "storage_account"     => $azure_account,
        "storage_account_key" => $azure_account_key,
        "container"           => $service['azure-storage-container'],
      },
    }

    $objstore_config_file = "${::profile::thanos::base::config_dir}/objstore-${dataset_name}.yml"
    file {$objstore_config_file:
      ensure  => present,
      owner   => 'root',
      group   => 'prometheus',
      mode    => '0640',
      content => inline_yaml($objstore_config),
      require => File[$::profile::thanos::base::config_dir],
    }

    $port_http = $service['port-http']
    $http_address = "${internal_ip}:${port_http}"
    $port_grpc = $service['port-grpc']
    $grpc_address = "${internal_ip}:${port_grpc}"
    $grpc_target  = "${swh_hostname['internal_fqdn']}:${port_grpc}"

    $service_name = "thanos-gateway@${dataset_name}"
    $unit_name = "${service_name}.service"

    ::systemd::dropin_file {"${service_name}/parameters.conf":
      ensure   => present,
      unit     => $unit_name,
      filename => 'parameters.conf',
      content  => template('profile/thanos/gateway-parameters.conf.erb'),
      notify   => Service[$service_name],
    }

    service {$service_name:
      ensure  => 'running',
      enable  => true,
      require => [
        File[$cert_paths['fullchain']],
        File[$cert_paths['privkey']],
      ],
      tag     => 'thanos-gateway',
    }

    # Ensure service is restarted when the certs are renewed
    File[$cert_paths['fullchain']] ~> Service[$service_name]
    File[$cert_paths['privkey']]   ~> Service[$service_name]

    # gateway service grpc address pushed to query service configuration file to access
    # historical data
    ::profile::thanos::export_query_endpoint {"thanos-gateway-${grpc_target}":
      grpc_address => $grpc_target
    }
  }

  # Uses: $config_dir, $cert_paths
  systemd::unit_file {'thanos-gateway@.service':
    ensure  => present,
    content => template('profile/thanos/gateway@.service.erb'),
    require => Class['profile::thanos::base'],
  } ~> Service <| tag == 'thanos-gateway' |>
}
