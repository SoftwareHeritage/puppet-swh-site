# Prometheus configuration for nodes
class profile::prometheus::node {
  include profile::prometheus::apt_config

  $defaults_file = '/etc/default/prometheus-node-exporter'

  package {'prometheus-node-exporter':
    ensure => latest,
    notify => Service['prometheus-node-exporter'],
  }

  service {'prometheus-node-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-node-exporter'],
      File[$defaults_file],
    ]
  }

  $lookup_defaults_config = lookup('prometheus::node::defaults_config', Hash)
  $listen_network = lookup('prometheus::node::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::node::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::node::listen_port')
  $target = "${actual_listen_address}:${listen_port}"

  $defaults_config = deep_merge(
    $lookup_defaults_config,
    {
      web => {
        listen_address => $target,
      },
    }
  )

  # Uses $defaults_config
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/node/prometheus-node-exporter.defaults.erb'),
    require => Package['prometheus-node-exporter'],
    notify  => Service['prometheus-node-exporter'],
  }

  profile::prometheus::export_scrape_config {'node':
    target => $target,
  }
}
