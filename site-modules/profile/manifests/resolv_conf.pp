# Configure resolv.conf
class profile::resolv_conf {
  $nameservers = lookup('dns::nameservers')
  $search_domains = lookup('dns::search_domains')

  class {'::resolv_conf':
    nameservers => $nameservers,
    searchpath  => $search_domains,
  }

  file {['/etc/dhcp', '/etc/dhcp/dhclient-enter-hooks.d']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file {'/etc/dhcp/dhclient-enter-hooks.d/noresolvconf':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/resolv_conf/dhcp-noresolvconf',
  }
}
