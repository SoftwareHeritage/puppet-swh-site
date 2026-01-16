# Prometheus configuration for apache exporter
class profile::prometheus::apache {
  include profile::prometheus::base

  $defaults_file = '/etc/default/prometheus-apache-exporter'

  $listen_network = lookup('prometheus::apache::listen_network')
  $listen_address = lookup('prometheus::apache::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::apache::listen_port')
  $exporter_url = "${actual_listen_address}:${listen_port}"

  package {'prometheus-apache-exporter':
    ensure => present,
    notify => Service['prometheus-apache-exporter'],
  }

  service {'prometheus-apache-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-apache-exporter'],
      File[$defaults_file],
    ]
  }

  ::systemd::dropin_file {'prometheus-apache-exporter/restart.conf':
    ensure   => present,
    unit     => 'prometheus-apache-exporter.service',
    filename => 'restart.conf',
    content  => "[Service]\nRestart=always\nRestartSec=5\n",
  }

  # Uses $exporter_url
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/apache/prometheus-apache-exporter.defaults.erb'),
    require => Package['prometheus-apache-exporter'],
    notify  => Service['prometheus-apache-exporter'],
  }

  profile::prometheus::export_scrape_config {'apache':
    target => $exporter_url,
  }
}
