# Puppet agent profile
class profile::puppet::agent {
  $puppetmaster = hiera('puppet::master::hostname')

  include ::profile::puppet::base

  class { '::puppet':
    * => $::profile::puppet::base::agent_config,
  }
}
