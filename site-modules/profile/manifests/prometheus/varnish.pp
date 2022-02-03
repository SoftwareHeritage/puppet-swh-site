# Prometheus configuration for varnish exporter
class profile::prometheus::varnish {
  include profile::prometheus::base

  $defaults_file = '/etc/default/prometheus-varnish-exporter'
  $varnish_user = 'varnish'
  $listen_network = lookup('prometheus::varnish::listen_network')
  $listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::varnish::listen_port')
  $exporter_url = "${listen_address}:${listen_port}"

  package {'prometheus-varnish-exporter':
    ensure => present,
    notify => Service['prometheus-varnish-exporter'],
  }

  service {'prometheus-varnish-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-varnish-exporter'],
      File[$defaults_file],
    ]
  }

  ::systemd::dropin_file {'prometheus-varnish-exporter/config.conf':
    ensure   => present,
    unit     => 'prometheus-varnish-exporter.service',
    filename => 'user.conf',
    content  => "[Service]\nUser=${varnish_user}\n",
  }
  ::systemd::dropin_file {'prometheus-varnish-exporter/restart.conf':
    ensure   => present,
    unit     => 'prometheus-varnish-exporter.service',
    filename => 'restart.conf',
    content  => "[Service]\nRestart=always\nRestartSec=5\n",
  }

  # Uses $exporter_url
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/varnish/prometheus-varnish-exporter.defaults.erb'),
    require => Package['prometheus-varnish-exporter'],
    notify  => Service['prometheus-varnish-exporter'],
  }

  profile::prometheus::export_scrape_config {'varnish':
    target => $exporter_url,
  }
}
