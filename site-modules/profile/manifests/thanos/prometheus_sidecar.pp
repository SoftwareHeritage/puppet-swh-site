# Thanos prometheus sidecar
class profile::thanos::prometheus_sidecar {
  include profile::thanos::base
  include profile::thanos::tls_certificate

  $service_name = 'thanos-sidecar'
  $unit_name = "${service_name}.service"

  $objstore_config = lookup('thanos::objstore::config')
  $objstore_config_file = "${::profile::thanos::base::config_dir}/objstore.yml"

  $port_http = lookup('thanos::sidecar::port_http')
  $port_grpc = lookup('thanos::sidecar::port_grpc')

  $internal_ip = ip_for_network(lookup('internal_network'))
  $grpc_address = "${internal_ip}:${port_grpc}"
  $grpc_target = "${swh_hostname['internal_fqdn']}:${port_grpc}"

  $cert_paths = $::profile::thanos::tls_certificate::cert_paths

  $sidecar_arguments = {
    tsdb                   => {
      path => '/var/lib/prometheus/metrics2',
    },
    prometheus             => {
      # use the listen address for the prometheus server
      url => "http://${::profile::prometheus::server::target}/",
    },
    objstore               => {
      'config-file' => $objstore_config_file,
    },
    shipper                => {
      'upload-compacted' => true,
    },
    'grpc-server-tls-cert' => $cert_paths['fullchain'],
    'grpc-server-tls-key'  => $cert_paths['privkey'],
    'http-address'         => "${internal_ip}:${port_http}",
    'grpc-address'         => $grpc_address,
  }

  file {$objstore_config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'prometheus',
    mode    => '0640',
    content => inline_yaml($objstore_config),
    require => File[$::profile::thanos::base::config_dir],
  }

  # Template uses:
  # $sidecar_arguments
  systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/thanos/thanos-sidecar.service.erb'),
    require => Class['profile::thanos::base'],
    notify  => Service[$service_name]
  }

  service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => [
      Service['prometheus'],
      File[$cert_paths['fullchain']],
      File[$cert_paths['privkey']],
    ],
    tag     => 'thanos',
  }

  # Ensure prometheus is configured properly before starting the sidecar
  Exec['restart-prometheus'] -> Service[$service_name]

  # Ensure service is restarted when the certs are renewed
  File[$cert_paths['fullchain']] ~> Service[$service_name]
  File[$cert_paths['privkey']]   ~> Service[$service_name]

  ::profile::thanos::export_query_endpoint {"thanos-sidecar-${::fqdn}":
    grpc_address => $grpc_target
  }

  $http_target = "${swh_hostname['internal_fqdn']}:${port_http}"
  ::profile::prometheus::export_scrape_config {"thanos-sidecar-${::fqdn}":
    target => $http_target,
    job    => 'thanos_sidecar',
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  @@::icinga2::object::service {"thanos sidecar on ${::fqdn}":
    service_name  => 'thanos sidecar',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'check_prometheus_metric',
    vars          => {
      'check_prometheus_query'           => profile::icinga2::literal_var(
        join([
          'time() - thanos_objstore_bucket_last_successful_upload_time{job="thanos_sidecar", instance="',
          $swh_hostname['internal_fqdn'],
          '"}',
        ])
      ),
      'check_prometheus_metric_name'     => 'thanos_sidecar_upload_lag',
      # We expect an upload every 2 hours
      'check_prometheus_metric_warning'  => 3 * 3600,
      'check_prometheus_metric_critical' => 24 * 3600,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
