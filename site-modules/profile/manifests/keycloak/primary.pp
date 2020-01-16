# Definition for the primary keycloak server

class profile::keycloak::primary {
  $backend_port = lookup('keycloak::backend::port')

  $postgres_host = lookup('keycloak::postgres::host')
  $postgres_port = lookup('keycloak::postgres::port')
  $postgres_dbname = lookup('keycloak::postgres::dbname')
  $postgres_user = lookup('keycloak::postgres::user')
  $postgres_password = lookup('keycloak::postgres::password')

  class {'::keycloak':
    # Bind address
    http_port            => $backend_port,

    # Database settings
    datasource_driver    => 'postgresql',
    datasource_host      => $postgres_host,
    datasource_port      => $postgres_port,
    datasource_dbname    => $postgres_dbname,
    datasource_username  => $postgres_user,
    datasource_password  => $postgres_password,
    # Don't manage the PostgreSQL database
    manage_datasource    => false,
  }
}
