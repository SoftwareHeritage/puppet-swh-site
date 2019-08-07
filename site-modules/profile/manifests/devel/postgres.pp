class profile::devel::postgres {
  $packages = lookup('packages::devel::postgres', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  $dbs = lookup('swh::postgres::service::dbs', Array, 'deep')

  # Explicitly install the configuration files per user's home
  # TL;DR the pgpass must be readonly per user so we can't use the global one
  $users = lookup('swh::postgres::service::users', Array, 'deep')
  each ($users) | $user | {
    if $user == 'root' {
      $home = '/root'
    } else {
      $home = "/home/${user}"
    }

    file {"/${home}/.pg_service.conf":
      ensure  => file,
      content => template('profile/postgres/pg_service.conf.erb'),
      user => $user,
      group => $user,
      mode => '0400',
    }
    file {"/${user}/.pgpass":
      ensure  => file,
      content => template('profile/postgres/pgpass.conf.erb'),
      user => $user,
      group => $user,
      mode => '0400',
    }
  }

}
