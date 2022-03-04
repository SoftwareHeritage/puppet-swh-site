# Prometheus configuration for nginx exporter
class profile::prometheus::nginx {
  include profile::prometheus::base

  $defaults_file = '/etc/default/prometheus-nginx-exporter'
  $nginx_metrics_port = lookup('nginx::metrics_port')
  $nginx_metrics_location = lookup('nginx::metrics_location')
  $scrape_uri = "http://127.0.0.1:${nginx_metrics_port}${nginx_metrics_location}"
  $listen_network = lookup('prometheus::nginx::listen_network')
  $listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::nginx::listen_port')
  $target = "${listen_address}:${listen_port}"

  package {'prometheus-nginx-exporter':
    ensure => present,
    notify => Service['prometheus-nginx-exporter'],
  }

  service {'prometheus-nginx-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-nginx-exporter'],
      File[$defaults_file],
    ]
  }

  ::systemd::dropin_file {'prometheus-nginx-exporter/restart.conf':
    ensure   => present,
    unit     => 'prometheus-nginx-exporter.service',
    filename => 'restart.conf',
    content  => "[Service]\nRestart=always\nRestartSec=5\n",
  }

  ::systemd::dropin_file {'prometheus-nginx-exporter/ordering.conf':
    ensure   => present,
    unit     => 'prometheus-nginx-exporter.service',
    filename => 'ordering.conf',
    content  => "[Unit]\nAfter=nginx.service\n",
  }

  # Uses $target and $scrape_uri
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/nginx/prometheus-nginx-exporter.defaults.erb'),
    require => Package['prometheus-nginx-exporter'],
    notify  => Service['prometheus-nginx-exporter'],
  }

  profile::prometheus::export_scrape_config {'nginx':
    target => $target,
  }
}
