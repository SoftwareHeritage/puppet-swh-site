# Puppet agent profile
class profile::puppet::agent {
  $puppetmaster = hiera('puppet::master::hostname')

  class { '::puppet':
    runmode      => 'none',
    pluginsync   => true,
    puppetmaster => $puppetmaster,
  }

  file { '/usr/local/sbin/swh-puppet-test':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-test.sh.erb'),
  }

  file { '/usr/local/sbin/swh-puppet-apply':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-apply.sh.erb'),
  }
}
