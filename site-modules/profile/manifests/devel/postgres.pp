class profile::devel::postgres {
  $packages = lookup('packages::devel::postgres', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  $dbs = lookup('swh::dbs::all', Array, 'deep')

  file { '/etc/postgresql-common/pg_service.conf':
    ensure  => file,
    content => template('profile/postgres/pg_service.conf.erb'),
    require => Package[$packages],
  }

  # Users who wants this need to install themselves
  # ln -s /etc/postgresql-common/pgpass.conf ~/.pgpass
  file { '/etc/postgresql-common/pgpass.conf':
    ensure  => file,
    mode   => '0600',
    content => template('profile/postgres/pgpass.conf.erb'),
    require => Package[$packages],
  }

}
