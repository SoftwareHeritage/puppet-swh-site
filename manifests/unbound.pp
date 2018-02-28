# Parameters for the unbound DNS resolver
class profile::unbound {
  $has_local_cache = lookup('dns::local_cache')

  $package = 'unbound'
  $service = 'unbound'
  $conf_dir = '/etc/unbound/unbound.conf.d'
  $forwarders_file = "${conf_dir}/forwarders.conf"
  $insecure_file = "${conf_dir}/insecure.conf"
  $auto_root_data = '/var/lib/unbound/root.key'

  if $has_local_cache {
    include ::profile::resolv_conf

    $forwarders = lookup('dns::forwarders')
    $forward_zones = lookup('dns::forward_zones')
    $insecure = lookup('dns::forwarder_insecure')

    package {$package:
      ensure => installed,
    }
    package {'dns-root-data':
      ensure => installed,
    }

    service {$service:
      ensure  => running,
      enable  => true,
      require => [
        Package[$package],
        File[$forwarders_file],
        File[$auto_root_data],
      ],
    }

    Service[$service] -> File['/etc/resolv.conf']

    # uses variables $forwarders, $forward_zones
    file {$forwarders_file:
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

    file {$insecure_file:
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

    file {$auto_root_data:
      ensure  => present,
      owner   => 'unbound',
      group   => 'unbound',
      mode    => '0644',
      replace => 'no',
      source  => '/usr/share/dns/root.key',
      require => [
        Package[$package],
        Package['dns-root-data'],
      ],
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
