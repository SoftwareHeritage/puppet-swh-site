# Deployment of web-facing internal site exposit a static backup of the www website
class profile::www_static_backup_web {

  $vhost_name = lookup('www_static_backup_web::vhost::name')
  $vhost_docroot = lookup('www_static_backup_web::vhost::docroot')

  include ::profile::apache::common

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername           => $vhost_name,
    port                 => 80,
    ssl                  => false,
    docroot              => $vhost_docroot,
    manage_docroot       => false,
    directories          => [
      {
        'path'     => $vhost_docroot,
        'require'  => 'all granted',
        'options'  => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      },
    ],
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_checks_hostname = lookup('icinga2::exported_checks::hostname')


  ::icinga2::object::service {"www-static-backup http on ${::fqdn}":
    service_name  => 'www-static-backup https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $vhost_name,
      http_vhost      => $vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    export        => [$icinga_checks_hostname]
  }

}
