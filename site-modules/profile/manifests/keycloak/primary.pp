# Definition for the primary keycloak server

class profile::keycloak::primary {
  $version = lookup('keycloak::version')

  $swh_theme_repo_url = lookup('keycloak::swh_theme::repo_url')
  $swh_theme_tag = lookup('keycloak::swh_theme::tag')

  $backend_port = lookup('keycloak::backend::port')

  $postgres_host = lookup('keycloak::postgres::host')
  $postgres_port = lookup('keycloak::postgres::port')
  $postgres_dbname = lookup('keycloak::postgres::dbname')
  $postgres_user = lookup('keycloak::postgres::user')
  $postgres_password = lookup('keycloak::postgres::password')

  $admin_user = lookup('keycloak::admin::user')
  $admin_password = lookup('keycloak::admin::password')

  class {'::keycloak':
    # Version number
    version              => $version,

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

  # Install Software Heritage theme for Keycloak
  vcsrepo { '/opt/swh-keycloak-theme':
    ensure   => present,
    provider => git,
    source   => $swh_theme_repo_url,
    revision => $swh_theme_tag,
    # keycloak service needs to be restarted when updating themes
    # as they are cached
    notify   => Service['keycloak'],
  }

  file { "/opt/keycloak-${version}/themes/swh":
    ensure  => link,
    target  => '/opt/swh-keycloak-theme/swh',
  }

  include ::profile::keycloak::resources
}
