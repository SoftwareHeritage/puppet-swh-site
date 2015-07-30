# Puppet agent profile
class profile::puppet::agent {
  $puppetmaster = hiera('puppet::master::hostname')

  class { '::puppet':
    runmode      => 'none',
    pluginsync   => true,
    puppetmaster => $puppetmaster,
  }
}
