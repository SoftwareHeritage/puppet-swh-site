# Puppet agent profile
class profile::puppet::agent {
  include ::profile::puppet::base

  class { '::puppet':
    * => $::profile::puppet::base::agent_config,
  }
}
