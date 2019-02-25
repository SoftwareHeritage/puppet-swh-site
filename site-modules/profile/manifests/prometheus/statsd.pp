# Prometheus configuration for statsd exporter
class profile::prometheus::statsd {
  include profile::prometheus::apt_config

  $defaults_file = '/etc/default/prometheus-statsd-exporter'
  $mapping_config_file = '/etc/prometheus/statsd_exporter_mapping.yml'

  package {'prometheus-statsd-exporter':
    ensure => present,
    notify => Service['prometheus-statsd-exporter'],
  }

  service {'prometheus-statsd-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-statsd-exporter'],
      File[$defaults_file],
    ]
  }

  ::systemd::dropin_file {'prometheus-statsd-exporter/restart.conf':
    ensure   => present,
    unit     => 'prometheus-statsd-exporter.service',
    filename => 'restart.conf',
    content  => "[Service]\nRestart=always\nRestartSec=5\n",
  }

  $lookup_defaults_config = lookup('prometheus::statsd::defaults_config', Hash)
  $listen_network = lookup('prometheus::statsd::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::statsd::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $prometheus_listen_port = lookup('prometheus::statsd::listen_port')
  $target = "${actual_listen_address}:${prometheus_listen_port}"

  $listen_tcp = lookup('prometheus::statsd::statsd_listen_tcp')
  $listen_udp = lookup('prometheus::statsd::statsd_listen_udp')

  $mapping_config = lookup('prometheus::statsd::mapping', Hash)


  $defaults_config = deep_merge(
    $lookup_defaults_config,
    {
      web => {
        listen_address => $target,
      },
      statsd => {
        mapping_config => $mapping_config_file,
        listen_tcp => $listen_tcp,
        listen_udp => $listen_udp,
      }
    }
  )

  # Uses $defaults_config
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/statsd/prometheus-statsd-exporter.defaults.erb'),
    require => Package['prometheus-statsd-exporter'],
    notify  => Service['prometheus-statsd-exporter'],
  }

  file {$mapping_config_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($mapping_config),
    require => Package['prometheus-statsd-exporter'],
    notify  => Service['prometheus-statsd-exporter'],
  }

  profile::prometheus::export_scrape_config {'statsd':
    target => $target,
  }
}
