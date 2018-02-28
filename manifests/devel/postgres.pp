class profile::devel::postgres {
  $packages = lookup('packages::devel::postgres', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  file { '/etc/postgresql-common/pg_service.conf':
    ensure  => file,
    content => template('profile/postgres/pg_service.conf.erb'),
    require => Package[$packages],
  }
}
