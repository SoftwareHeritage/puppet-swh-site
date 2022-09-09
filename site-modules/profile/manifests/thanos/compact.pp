# Thanos compact services (compaction and downscaling of historical metrics)
class profile::thanos::compact {
  include profile::thanos::base
  include profile::thanos::objstore_configs

  $internal_ip = ip_for_network(lookup('internal_network'))

  $stores = lookup('thanos::stores')

  $config_dir = $::profile::thanos::base::config_dir
  $stores.each | $dataset_name, $service | {
    $port_http = $service['compact']['port-http']
    $http_address = "${internal_ip}:${port_http}"
    $http_target  = "${swh_hostname['internal_fqdn']}:${port_http}"

    $service_name = "thanos-compact@${dataset_name}"
    $unit_name = "${service_name}.service"

    ::systemd::dropin_file {"${service_name}/parameters.conf":
      ensure   => present,
      unit     => $unit_name,
      filename => 'parameters.conf',
      content  => template('profile/thanos/compact-parameters.conf.erb'),
      notify   => Service[$service_name],
    }

    service {$service_name:
      ensure  => 'running',
      enable  => true,
      tag     => [
        'thanos',
        'thanos-compact',
        "thanos-objstore-${dataset_name}",
      ],
    }

    ::profile::prometheus::export_scrape_config {"thanos-compact-${http_target}":
      target => $http_target,
      job    => 'thanos_compact',
      labels => {
        dataset_name => $dataset_name,
      },
    }
  }

  # Uses: $config_dir, $cert_paths
  systemd::unit_file {'thanos-compact@.service':
    ensure  => present,
    content => template('profile/thanos/compact@.service.erb'),
    require => Class['profile::thanos::base'],
  } ~> Service <| tag == 'thanos-compact' |>
}
