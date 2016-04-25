class profile::devel::postgres {
  $packages = hiera_array('packages::devel::postgres')

  package { $packages:
    ensure => present,
  }

  file { '/etc/postgresql-common/pg_service.conf':
    ensure  => file,
    content => template('profile/postgres/pg_service.conf.erb'),
  }
}
