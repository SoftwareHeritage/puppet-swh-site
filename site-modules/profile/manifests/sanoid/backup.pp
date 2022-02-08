class profile::sanoid::backup {
  ensure_packages('sanoid')

  $config_dir = '/etc/sanoid'
  $config_file = "${config_dir}/sanoid.conf"
  $host_configuration = lookup('sanoid::configuration')
  $dataset_configuration = $host_configuration["local_config"]
  $sanoid_templates = lookup('sanoid::templates')

  file {$config_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # template uses $dataset_configuration and $sanoid_templates
  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sanoid/sanoid.conf.erb'),
    require => File[$config_dir],
  }

  file {'/usr/local/bin/start_pg_backup.sh':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0744',
    source => 'puppet:///modules/profile/sanoid/start_pg_backup.sh'
  }
  file {'/usr/local/bin/stop_pg_backup.sh':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0744',
    source => 'puppet:///modules/profile/sanoid/stop_pg_backup.sh'
  }

}

