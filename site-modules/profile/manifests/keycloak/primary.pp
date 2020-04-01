# Definition for the primary keycloak server

class profile::keycloak::primary {
  $backend_port = lookup('keycloak::backend::port')

  $postgres_host = lookup('keycloak::postgres::host')
  $postgres_port = lookup('keycloak::postgres::port')
  $postgres_dbname = lookup('keycloak::postgres::dbname')
  $postgres_user = lookup('keycloak::postgres::user')
  $postgres_password = lookup('keycloak::postgres::password')

  $admin_user = lookup('keycloak::admin::user')
  $admin_password = lookup('keycloak::admin::password')

  class {'::keycloak':
    # Virtual Host settings
    proxy_https          => true,

    # Bind address
    http_port            => $backend_port,

    # Admin user settings
    admin_user           => $admin_user,
    admin_user_password  => $admin_password,

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

  include ::profile::keycloak::resources
}
