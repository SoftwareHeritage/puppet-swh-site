class profile::base {
  class { '::ntp':
    servers => hiera('ntp::servers'),
  }
}
