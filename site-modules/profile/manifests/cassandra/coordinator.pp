# Class used to install coordinator scripts on cassandra like rolling restart of a
# cluster
class profile::cassandra::coordinator {

  $default_instance_config = lookup('cassandra::default_instance_configuration')
  $jmx_user = $default_instance_config['jmx_user']
  $jmx_password = $default_instance_config['jmx_password']

  file {"/etc/cassandra":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0775',
  }

  ~> file {"/etc/cassandra/staging-env.sh":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('profile/cassandra/staging-env.sh.erb'),
  }
  ~> file {"/etc/cassandra/production-env.sh":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('profile/cassandra/production-env.sh.erb'),
  }

  ['restart-cluster',
    'upgradesstables',
  ].each |$script| {
    file { "/usr/local/bin/cassandra-${script}.sh":
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0750',
      source => "puppet:///modules/profile/cassandra/cassandra-${script}.sh",
    }
  }
}
