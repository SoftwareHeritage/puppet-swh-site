# Apache virtual host for icingaweb2

class profile::icinga2::icingaweb2::vhost {
  include ::profile::ssl
  include ::profile::apache::common
  include ::apache::mod::php

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
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${icingaweb2_vhost_name}_ssl":
    servername           => $icingaweb2_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $icingaweb2_vhost_ssl_protocol,
    ssl_honorcipherorder => $icingaweb2_vhost_ssl_honorcipherorder,
    ssl_cipher           => $icingaweb2_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
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
        File[$ssl_chain],
        File[$ssl_key],
    ],
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

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
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
