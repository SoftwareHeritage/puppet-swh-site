# Puppet master profile
class profile::puppet::master {
  $puppetmaster = hiera('puppet::master::hostname')

  include profile::puppet::apt_config

  class { '::puppet':
    server                      => true,
    server_parser               => 'future',
    server_foreman              => false,
    server_environments         => [],
    server_passenger            => true,
    server_storeconfigs_backend => 'active_record',

    runmode                     => 'none',
    pluginsync                  => true,
    puppetmaster                => $puppetmaster,
  }

  file { '/usr/local/sbin/swh-puppet-master-deploy':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-master-deploy.sh.erb'),
  }

}
