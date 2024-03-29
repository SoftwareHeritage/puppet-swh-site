# Thanos store services (historical metrics access)
class profile::thanos::store {
  include profile::thanos::base
  include profile::thanos::tls_certificate
  include profile::thanos::objstore_configs

  $cert_paths = $::profile::thanos::tls_certificate::cert_paths

  $internal_ip = ip_for_network(lookup('internal_network'))

  $stores = lookup('thanos::stores')

  $config_dir = $::profile::thanos::base::config_dir
  $stores.each | $dataset_name, $service | {
    $port_http = $service['store']['port-http']
    $http_address = "${internal_ip}:${port_http}"
    $http_target  = "${swh_hostname['internal_fqdn']}:${port_http}"

    $port_grpc = $service['store']['port-grpc']
    $grpc_address = "${internal_ip}:${port_grpc}"
    $grpc_target  = "${swh_hostname['internal_fqdn']}:${port_grpc}"

    $service_name = "thanos-store@${dataset_name}"
    $unit_name = "${service_name}.service"

    ::systemd::dropin_file {"${service_name}/parameters.conf":
      ensure   => present,
      unit     => $unit_name,
      filename => 'parameters.conf',
      content  => template('profile/thanos/store-parameters.conf.erb'),
      notify   => Service[$service_name],
    }

    service {$service_name:
      ensure  => 'running',
      enable  => true,
      require => [
        File[$cert_paths['fullchain']],
        File[$cert_paths['privkey']],
      ],
      tag     => [
        'thanos',
        'thanos-store',
        "thanos-objstore-${dataset_name}",
      ],
    }

    # Ensure service is restarted when the certs are renewed
    File[$cert_paths['fullchain']] ~> Service[$service_name]
    File[$cert_paths['privkey']]   ~> Service[$service_name]

    # store service grpc address pushed to query service configuration file to access
    # historical data
    ::profile::thanos::export_query_endpoint {"thanos-store-${grpc_target}":
      grpc_address => $grpc_target
    }

    ::profile::prometheus::export_scrape_config {"thanos-store-${http_target}":
      target => $http_target,
      job    => 'thanos_store',
      labels => {
        dataset_name => $dataset_name,
      },
    }
  }

  # Uses: $config_dir, $cert_paths
  systemd::unit_file {'thanos-store@.service':
    ensure  => present,
    content => template('profile/thanos/store@.service.erb'),
    require => Class['profile::thanos::base'],
  } ~> Service <| tag == 'thanos-store' |>
}
