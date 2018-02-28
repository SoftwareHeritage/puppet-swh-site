# Base puppet configuration for all hosts.

class profile::puppet::base {
  $puppetmaster = lookup('puppet::master::hostname')

  $agent_config = {
    runmode             => 'none',
    pluginsync          => true,
    puppetmaster        => $puppetmaster,
    additional_settings => {
      environment_data_provider => 'hiera',
    },
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

  # Backported packages
  if $::lsbdistcodename == 'jessie' {
    $pinned_packages = [
      'facter',
      'hiera',
      'puppet',
      'puppet-common',
      'puppetmaster',
      'puppetmaster-common',
      'puppetmaster-passenger',
      'ruby-deep-merge',
    ]

    ::apt::pin {'puppet':
      explanation => 'Pin puppet dependencies to backports',
      codename    => 'jessie-backports',
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'puppet':
      ensure => 'absent',
    }
  }
}
