# Configuration for anubis protection for Apache Vhosts

class profile::anubis::apache {
  include ::profile::anubis
  include ::apache::mod::remoteip

  $bind_address = lookup('anubis::apache::listen_host')
  $bind_port = lookup('anubis::apache::listen_port')

  $apache_bind_address = lookup('apache::anubis_backend_listen')
  $target_address = ':' in $apache_bind_address ? {
    true    => "[${apache_bind_address}]",
    default => $apache_bind_address,
  } 
  $target_port = lookup('apache::anubis_backend_port')

  ::apache::listen {"${target_address}:${target_port}":}
 
  $metrics_listen_network = lookup('prometheus::anubis_apache::listen_network')
  $metrics_listen_address = lookup('prometheus::anubis_apache::listen_address', Optional[String], 'first', undef)
  $actual_metrics_listen_address = pick($metrics_listen_address, ip_for_network($metrics_listen_network))
  $metrics_listen_port = lookup('prometheus::anubis_apache::listen_port')

  profile::prometheus::export_scrape_config {'anubis_apache':
    target => "${actual_metrics_listen_address}:${metrics_listen_port}",
  }

  $policy_filename = '/etc/anubis/apache.botPolicies.yaml'

  file {'/etc/anubis/apache.env':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/anubis/anubis.env.erb'),
    require => Package['anubis'],
    notify  => Service['anubis@apache.service'],
  }

  file {$policy_filename:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/anubis/apache.botPolicies.yaml',
    require => Package['anubis'],
    notify  => Service['anubis@apache.service'],
  }

  service {'anubis@apache.service':
    enable  => true,
    ensure  => running,
    tag     => 'anubis',
    require => [
      File['/etc/anubis/apache.env', '/etc/anubis/apache.botPolicies.yaml'],
      Package['anubis'],
    ],
  }
  
}
