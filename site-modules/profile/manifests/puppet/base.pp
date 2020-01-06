# Base puppet configuration for all hosts.

class profile::puppet::base {
  $puppetmaster = lookup('puppet::master::hostname')

  $agent_config = {
    runmode             => 'none',
    pluginsync          => true,
    puppetmaster        => $puppetmaster,
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

  profile::cron::d {'puppet-agent':
    target  => 'puppet',
    command => 'puppet agent --onetime --no-daemonize --no-splay --verbose --logdest syslog',
    minute =>  'fqdn_rand/30',
  }

  # Backported packages
  if $::lsbdistcodename == 'stretch' {
    $pinned_packages = [
      'facter',
      'libfacter*',
      'libleatherman*',
      'libleatherman-data',
      'libcpp-hocon*',
    ]
  }
  else {
    $pinned_packages = undef
  }

  if $pinned_packages {
    ::apt::pin {'puppet':
      explanation => 'Pin puppet dependencies to backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'puppet':
      ensure => 'absent',
    }
  }
}
