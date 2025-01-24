# Puppet configuration
class profile::puppet {
  include ::profile::puppet::apt_config

  $puppet_server = lookup('puppet::server::hostname')

  $agent_config = {
    runmode               => 'none',
    agent_server_hostname => $puppet_server,
  }

  $is_puppetserver = $puppet_server in values($::swh_hostname)

  if $is_puppetserver {
    include ::profile::puppet::server
  } else {
    class {'::puppet':
      * => $agent_config,
    }
  }

  file { '/usr/local/sbin/swh-puppet-test':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/puppet/swh-puppet-test.sh',
  }

  file { '/usr/local/sbin/swh-puppet-apply':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source => 'puppet:///modules/profile/puppet/swh-puppet-apply.sh',
  }

  profile::cron::d {'puppet-agent':
    target  => 'puppet',
    command => 'puppet agent --onetime --no-daemonize --no-splay --verbose --logdest syslog',
    minute =>  'fqdn_rand/30',
  }
}
