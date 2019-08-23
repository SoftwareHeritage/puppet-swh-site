# Rsnapshot master host
class profile::rsnapshot::master {

  $backup_exclusion = lookup('dar::backup::exclude', Array, 'unique')

  file {'/etc/rsnapshot.conf':
    content => template('profile/swh/rsnapshot.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file {'/srv/rsnapshot':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/var/log/rsnapshot':
    ensure  => directory,
    owner   => $rsnapshot_user,
    group   => $rsnapshot_group,
    mode    => '0700',
  }

  package { 'rsnapshot':
    ensure => 'present',
  }

  cron { 'rsnapshot_hourly':
    command => '/usr/bin/rsnapshot hourly',
    user    => 'root',
    hour    => '*/4',
    minute  => '0',
  }

  cron { 'rsnapshot_daily':
    command => '/usr/bin/rsnapshot daily',
    user    => 'root',
    hour    => '22',
    minute  => '33',
  }

}