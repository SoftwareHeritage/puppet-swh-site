# Thanos prometheus sidecar
class profile::thanos::prometheus_sidecar {
  include profile::thanos::base

  $service_name = 'thanos-sidecar'
  $unit_name = "${service_name}.service"

  $objstore_config = lookup('thanos::objstore::config')

  $config_dir = '/etc/thanos-sidecar'
  $objstore_config_file = "${config_dir}/objstore.yml"

  $sidecar_arguments = {
    tsdb           => {
      path => '/var/lib/prometheus/metrics2',
    },
    prometheus     => {
      # use the listen address for the prometheus server
      url => "http://${::profile::prometheus::server::target}/",
    },
    objstore       => {
      'config-file' => $objstore_config_file,
    },
    'http-address' => '0.0.0.0:19191',
    'grpc-address' => '0.0.0.0:19090',
  }


  file {$config_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'prometheus',
    mode    => '0750',
    require => Package['prometheus'],
  }

  file {$objstore_config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'prometheus',
    mode    => '0640',
    content => inline_yaml($objstore_config),
  }

  systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/thanos/thanos-sidecar.service.erb'),
    require => Class['profile::thanos::base'],
    notify  => Service[$service_name]
  }

  service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => Service['prometheus'],
  }

  Class['profile::thanos::base'] ~> Service[$service_name]
  # Ensure prometheus is configured properly before starting the sidecar
  Exec['restart-prometheus'] -> Service[$service_name]
}
