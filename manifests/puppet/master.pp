# Puppet master profile
class profile::puppet::master {
  $puppetdb = hiera('puppet::master::puppetdb')

  include ::profile::puppet::base

  class { '::puppet':
    server                      => true,
    server_foreman              => false,
    server_environments         => [],
    server_passenger            => true,
    server_puppetdb_host        => $puppetdb,
    server_reports              => 'puppetdb',
    server_storeconfigs_backend => 'puppetdb',

    *                           => $::profile::puppet::base::agent_config,
  }

  file { '/usr/local/sbin/swh-puppet-master-deploy':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-master-deploy.sh.erb'),
  }

}
