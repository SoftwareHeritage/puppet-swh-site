# Apache virtual host for icingaweb2

class profile::icinga2::icingaweb2::vhost {
  include ::profile::apache::common
  include ::apache::mod::php

  $icingaweb2_vhost_name = lookup('icinga2::icingaweb2::vhost::name')
  $icingaweb2_vhost_aliases = lookup('icinga2::icingaweb2::vhost::aliases')
  $icingaweb2_vhost_docroot = '/usr/share/icingaweb2/public'
  $icingaweb2_vhost_ssl_protocol = lookup('icinga2::icingaweb2::vhost::ssl_protocol')
  $icingaweb2_vhost_ssl_honorcipherorder = lookup('icinga2::icingaweb2::vhost::ssl_honorcipherorder')
  $icingaweb2_vhost_ssl_cipher = lookup('icinga2::icingaweb2::vhost::ssl_cipher')
  $icingaweb2_vhost_hsts_header = lookup('icinga2::icingaweb2::vhost::hsts_header')

  ::apache::vhost {"${icingaweb2_vhost_name}_non-ssl":
    servername      => $icingaweb2_vhost_name,
    serveraliases   => $icingaweb2_vhost_aliases,
    port            => '80',
    docroot         => $icingaweb2_vhost_docroot,
    manage_docroot  => false,  # will be managed by the SSL resource
    redirect_status => 'permanent',
    redirect_dest   => "https://${icingaweb2_vhost_name}/",
  }

  ::profile::letsencrypt::certificate {$icingaweb2_vhost_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($icingaweb2_vhost_name)

  ::apache::vhost {"${icingaweb2_vhost_name}_ssl":
    servername           => $icingaweb2_vhost_name,
    serveraliases        => $icingaweb2_vhost_aliases,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $icingaweb2_vhost_ssl_protocol,
    ssl_honorcipherorder => $icingaweb2_vhost_ssl_honorcipherorder,
    ssl_cipher           => $icingaweb2_vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
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
      File[$cert_paths['cert']],
      File[$cert_paths['chain']],
      File[$cert_paths['privkey']],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  @@::icinga2::object::service {"icingaweb2 http redirect on ${::fqdn}":
    service_name  => 'icingaweb2 http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $icingaweb2_vhost_name,
      http_vhost   => $icingaweb2_vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"icingaweb2 https on ${::fqdn}":
    service_name  => 'icingaweb2 https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $icingaweb2_vhost_name,
      http_vhost   => $icingaweb2_vhost_name,
      http_ssl     => true,
      http_sni     => true,
      http_uri     => '/authentication/login',
      http_header  => ['Cookie: _chc=1'],
      http_string  => '<title>Icinga Web 2 Login</title>',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"icingaweb2 https certificate ${::fqdn}":
    service_name  => 'icingaweb2 https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $icingaweb2_vhost_name,
      http_vhost       => $icingaweb2_vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 25,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
