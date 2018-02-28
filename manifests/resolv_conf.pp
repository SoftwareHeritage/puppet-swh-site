# Configure resolv.conf
class profile::resolv_conf {
  $nameservers = lookup('dns::nameservers')
  $search_domains = lookup('dns::search_domains')

  class {'::resolv_conf':
    nameservers => $nameservers,
    searchpath  => $search_domains,
  }
}
