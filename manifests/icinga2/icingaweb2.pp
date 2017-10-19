# Icinga web 2 configuration
class profile::icinga2::icingaweb2 {
  $icinga2_db_username = hiera('icinga2::master::db::username')
  $icinga2_db_password = hiera('icinga2::master::db::password')
  $icinga2_db_database = hiera('icinga2::master::db::database')

  $icingaweb2_db_username = hiera('icinga2::icingaweb2::db::username')
  $icingaweb2_db_password = hiera('icinga2::icingaweb2::db::password')
  $icingaweb2_db_database = hiera('icinga2::icingaweb2::db::database')

  include profile::icinga2::apt_config

  class {'::icingaweb2':
    manage_repo    => false,
    manage_package => true,
    import_schema  => true,
    db_type        => 'pgsql',
    db_host        => 'localhost',
    db_port        => 5432,
    db_username    => $icingaweb2_db_username,
    db_password    => $icingaweb2_db_password,
    require        => Postgresql::Server::Db[$icingaweb2_db_database],
  }

  ::postgresql::server::db {$icingaweb2_db_database:
    user     => $icingaweb2_db_username,
    password => postgresql_password($icingaweb2_db_username, $icingaweb2_db_password),
  }

  class {'::icingaweb2::module::monitoring':
    ido_host          => 'localhost',
    ido_db_name       => $icinga2_db_database,
    ido_db_username   => $icinga2_db_username,
    ido_db_password   => $icinga2_db_password,
    commandtransports => {
      icinga2 => {
        transport => 'local',
        path      => '/var/run/icinga2/cmd/icinga2.cmd',
      }
    }
  }

  include ::icingaweb2::module::doc

  include ::profile::ssl
  include ::profile::apache::common
  include ::apache2::mod::php

  $icingaweb2_vhost_name = hiera('icinga2::icingaweb2::vhost::name')
  $icingaweb2_vhost_aliases = hiera('icinga2::icingaweb2::vhost::aliases')
  $icingaweb2_vhost_docroot = '/usr/share/icingaweb2/public'
  $icingaweb2_vhost_ssl_protocol = hiera('icinga2::icingaweb2::vhost::ssl_protocol')
  $icingaweb2_vhost_ssl_honorcipherorder = hiera('icinga2::icingaweb2::vhost::ssl_honorcipherorder')
  $icingaweb2_vhost_ssl_cipher = hiera('icinga2::icingaweb2::vhost::ssl_cipher')
  $icingaweb2_vhost_hsts_header = hiera('icinga2::icingaweb2::vhost::hsts_header')

  ::apache::vhost {"${icingaweb2_vhost_name}_non-ssl":
    servername      => $icingaweb2_vhost_name,
    serveraliases   => $icingaweb2_vhost_aliases,
    port            => '80',
    docroot         => $icingaweb2_vhost_docroot,
    manage_docroot  => false,  # will be managed by the SSL resource
    redirect_status => 'permanent',
    redirect_dest   => "https://${icingaweb2_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${icingaweb2_vhost_name}_ssl":
    servername           => $icingaweb2_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $icingaweb2_vhost_ssl_protocol,
    ssl_honorcipherorder => $icingaweb2_vhost_ssl_honorcipherorder,
    ssl_cipher           => $icingaweb2_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_ca               => $ssl_ca,
    ssl_key              => $ssl_key,
    headers              => [$icingaweb2_vhost_hsts_header],
    docroot              => $icingaweb2_vhost_docroot,
    manage_docroot       => false,
    directories          => [
      {
        path           => $icingaweb2_vhost_docroot,
        require        => 'all granted',
        options        => ['SymlinksIfOwnerMatch'],
        setenv         => ['ICINGAWEB_CONFIGDIR "/etc/icingaweb2"'],
        allow_override => ['None'],
        rewrites       => [
          {
            rewrite_cond => [
              '%{REQUEST_FILENAME} -s [OR]',
              '%{REQUEST_FILENAME} -l [OR]',
              '%{REQUEST_FILENAME} -d',
            ],
            rewrite_rule => '^.*$ - [NC,L]',
          },
          {
            rewrite_rule => '^.*$ index.php [NC,L]',
          }
        ],
      },
    ],
    require              => [
        File[$ssl_cert],
        File[$ssl_ca],
        File[$ssl_key],
    ],
  }
}
