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
    $insecure = hiera('dns::forwarder_insecure')

    package {$package:
      ensure => installed,
    }

    service {$service:
      ensure  => running,
      enable  => true,
      require => [
        Package[$package],
        File[$forwarders_file],
      ],
    }

    Service[$service] -> File['/etc/resolv.conf']

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

    $insecure_ensure = $insecure ? {
      true    => present,
      default => absent,
    }

    file {'/etc/unbound/unbound.conf.d/insecure.conf':
      ensure  => $insecure_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/profile/unbound/insecure.conf',
      require => Package[$package],
      notify  => Service[$service],
    }

    file {'/etc/default/unbound':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package[$package],
    }

    file_line {'unbound root auto update':
      ensure  => present,
      path    => '/etc/default/unbound',
      match   => '^ROOT_TRUST_ANCHOR_UPDATE\=',
      line    => 'ROOT_TRUST_ANCHOR_UPDATE=false',
      require => Package[$package],
      notify  => Service[$service],
    }
  }
}
