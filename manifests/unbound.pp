# Parameters for the unbound DNS resolver
class profile::unbound {
  $has_local_cache = hiera('dns::local_cache')

  $package = 'unbound'
  $service = 'unbound'
  $forwarders_file = '/etc/unbound/unbound.conf.d/forwarders.conf'

  if $has_local_cache {
    $forwarders = hiera('dns::forwarders')
    $forward_zones = hiera('dns::forward_zones')

    package {$package:
      ensure => installed,
    }

    service {$service:
      ensure  => started,
      enable  => true,
      require => [
        Package[$package],
        File[$forwarders_file],
      ]
    }

    # uses variables $forwarders, $forward_zones
    file {'/etc/unbound/unbound.conf.d/forwarders.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('profile/unbound/forwarders.conf.erb'),
      require => Package[$package],
      notify  => Service[$service],
    }
  }
}
