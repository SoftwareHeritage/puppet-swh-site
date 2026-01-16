# Varnish-specific configuration for anubis

class profile::anubis::varnish {
  include profile::anubis

  $bind_address = lookup('anubis::varnish::listen_host')
  $bind_port = lookup('anubis::varnish::listen_port')

  $target_address = lookup('varnish::anubis_backend_listen')
  $target_port = lookup('varnish::anubis_backend_port')

  $metrics_listen_network = lookup('prometheus::anubis_varnish::listen_network')
  $metrics_listen_address = lookup('prometheus::anubis_varnish::listen_address', Optional[String], 'first', undef)
  $actual_metrics_listen_address = pick($metrics_listen_address, ip_for_network($metrics_listen_network))
  $metrics_listen_port = lookup('prometheus::anubis_varnish::listen_port')

  profile::prometheus::export_scrape_config {'anubis_varnish':
    target => "${actual_metrics_listen_address}:${metrics_listen_port}",
  }

  $policy_filename = '/etc/anubis/varnish.botPolicies.yaml'

  file {'/etc/anubis/varnish.env':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/anubis/varnish.env.erb'),
    require => Package['anubis'],
    notify  => Service['anubis@varnish.service'],
  }

  file {$policy_filename:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/anubis/varnish.botPolicies.yaml',
    require => Package['anubis'],
    notify  => Service['anubis@varnish.service'],
  }

  service {'anubis@varnish.service':
    enable  => true,
    ensure  => running,
    tag     => 'anubis',
    require => [
      File['/etc/anubis/varnish.env', '/etc/anubis/varnish.botPolicies.yaml'],
      Package['anubis'],
    ],
  }
}
