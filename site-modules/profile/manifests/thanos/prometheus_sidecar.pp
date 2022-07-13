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
  }

  Class['profile::thanos::base'] ~> Service[$service_name]
  # Ensure prometheus is configured properly before starting the sidecar
  Exec['restart-prometheus'] -> Service[$service_name]

  # Ensure service is restarted when the certs are renewed
  File[$cert_paths['fullchain']] ~> Service[$service_name]
  File[$cert_paths['privkey']]   ~> Service[$service_name]

  ::profile::thanos::export_query_endpoint {"thanos-sidecar-${::fqdn}":
    grpc_address => $grpc_target
  }
}
