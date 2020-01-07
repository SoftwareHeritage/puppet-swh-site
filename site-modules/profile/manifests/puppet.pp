# Puppet configuration
class profile::puppet {
  include ::profile::puppet::apt_config

  $puppetmaster = lookup('puppet::master::hostname')

  $agent_config = {
    runmode             => 'none',
    pluginsync          => true,
    puppetmaster        => $puppetmaster,
  }

  $is_puppetmaster = $puppetmaster in values($::swh_hostname)

  if $is_puppetmaster {
    include ::profile::puppet::master
  } else {
    class {'::puppet':
      * => $agent_config,
    }
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
}
