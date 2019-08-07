class profile::devel::postgres {
  $packages = lookup('packages::devel::postgres', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  $dbs = lookup('swh::postgres::service::dbs', Array, 'deep')

  # globally installed
  file { '/etc/postgresql-common/pg_service.conf':
    ensure  => file,
    content => template('profile/postgres/pg_service.conf.erb'),
    require => Package[$packages],
  }

  file { '/etc/postgresql-common/pgpass.conf':
    ensure  => file,
    mode   => '0600',
    content => template('profile/postgres/pgpass.conf.erb'),
    require => Package[$packages],
  }

  # Explicitly install the configuration files per user's home
  # TL;DR the pgpass must be readonly per user so we can't use the global one
  # FIXME: might as well remove the global one
  $users = lookup('swh::postgres::service::users', Array, 'deep')
  each ($users) | $user | {
    file {"/home/${user}/.pg_service.conf":
      ensure  => file,
      content => template('profile/postgres/pg_service.conf.erb'),
      user => $user,
      group => $user,
      mode => '0400',
    }
    file {"/home/${user}/.pgpass":
      ensure  => file,
      content => template('profile/postgres/pgpass.conf.erb'),
      user => $user,
      group => $user,
      mode => '0400',
    }
  }

}
