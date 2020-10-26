class profile::postgresql::client {
  include profile::postgresql::apt_config

  package { 'postgresql-client':
    ensure => present,
  }

  # This part installs per user the postgresql client files ~/.pg_service.conf
  # and ~/.pgpass https://intranet.softwareheritage.org/wiki/Databases
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

    file {"${home}/.pg_service.conf":
      ensure  => file,
      content => template('profile/postgres/pg_service.conf.erb'),
      owner   => $user,
      group   => $user,
      mode    => '0400',
    }
    file {"${home}/.pgpass":
      ensure  => file,
      content => template('profile/postgres/pgpass.conf.erb'),
      owner   => $user,
      group   => $user,
      mode    => '0400',
    }
  }

}
