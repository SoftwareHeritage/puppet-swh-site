# Configure resolv.conf
class profile::resolv_conf {
  $nameservers = hiera('dns::nameservers')
  $search_domains = hiera('dns::search_domains')

  class {'::resolv_conf':
    nameservers => $nameservers,
    searchpath  => $search_domains,
  }
}
