# Parameters for the unbound DNS resolver
class profile::unbound {
  $has_local_cache = hiera('dns::local_cache')

  $package = 'unbound'
  $service = 'unbound'
  $forwarders_file = '/etc/unbound/unbound.conf.d/forwarders.conf'

  if $has_local_cache {
    include ::profile::resolv_conf

    $forwarders = hiera('dns::forwarders')
    $forward_zones = hiera('dns::forward_zones')

    package {$package:
      ensure => installed,
    }

    service {$service:
      ensure  => running,
      enable  => true,
      require => [
        Package[$package],
        File[$forwarders_file],
      ]
    } -> File['/etc/resolv.conf']

    # uses variables $forwarders, $forward_zones
    file {'/etc/unbound/unbound.conf.d/forwarders.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profile/unbound/forwarders.conf.erb'),
      require => Package[$package],
      notify  => Service[$service],
    }
  }
}
