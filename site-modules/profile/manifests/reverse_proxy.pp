# A factored reverse proxy configuration
define profile::reverse_proxy (
  String $ssl_cert_name                 = $name,
  Hash $default_proxy_pass_opts         = {},
  Array[Hash] $extra_proxy_pass         = [],
  Array[String] $request_headers        = [
      'set X-Forwarded-Proto "https"',
      'set X-Forwarded-Port "443"',
  ],
  Hash $extra_apache_opts               = {},
  Optional[String] $icinga_check_string = undef,
){
  $backend_url = lookup("${name}::backend::url")

  include ::profile::ssl
  include ::profile::apache::common
  include ::apache::mod::proxy

  $vhost_name = lookup("${name}::vhost::name")
  $vhost_docroot = '/var/www/html'
  $vhost_ssl_protocol = lookup("${name}::vhost::ssl_protocol")
  $vhost_ssl_honorcipherorder = lookup("${name}::vhost::ssl_honorcipherorder")
  $vhost_ssl_cipher = lookup("${name}::vhost::ssl_cipher")
  $vhost_hsts_header = lookup("${name}::vhost::hsts_header")


  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $vhost_docroot,
    manage_docroot  => false,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  ::profile::letsencrypt::certificate {$ssl_cert_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($ssl_cert_name)

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
    headers              => [$vhost_hsts_header],
    docroot              => $vhost_docroot,
    manage_docroot       => false,

    proxy_pass           => [
      { path => '/',
        url  => $backend_url,
      } + $default_proxy_pass_opts,
    ] + $extra_proxy_pass,

    request_headers      => $request_headers,

    *                    => $extra_apache_opts,

    require              => [
      Profile::Letsencrypt::Certificate[$ssl_cert_name],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  @@::icinga2::object::service {"${name} http redirect on ${::fqdn}":
    service_name  => "${name} http redirect",
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  $_icinga_check_string = pick($icinga_check_string, capitalize($name))

  @@::icinga2::object::service {"${name} https on ${::fqdn}":
    service_name  => "${name} https",
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_ssl     => true,
      http_sni     => true,
      http_uri     => '/',
      http_string  => $_icinga_check_string,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"${name} https certificate ${::fqdn}":
    service_name  => "${name} https certificate",
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $vhost_name,
      http_vhost       => $vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
