# Apache virtual host for grafana

class profile::grafana::vhost {
  include ::profile::ssl
  include ::profile::apache::common
  include ::apache::mod::proxy

  $grafana_vhost_name = lookup('grafana::vhost::name')
  $grafana_vhost_docroot = '/var/www/html'
  $grafana_vhost_ssl_protocol = lookup('grafana::vhost::ssl_protocol')
  $grafana_vhost_ssl_honorcipherorder = lookup('grafana::vhost::ssl_honorcipherorder')
  $grafana_vhost_ssl_cipher = lookup('grafana::vhost::ssl_cipher')
  $grafana_vhost_hsts_header = lookup('grafana::vhost::hsts_header')
  $grafana_upstream_port = lookup('grafana::backend::port')
  $grafana_backend_url = "http://127.0.0.1:${grafana_upstream_port}/"

  ::apache::vhost {"${grafana_vhost_name}_non-ssl":
    servername      => $grafana_vhost_name,
    port            => '80',
    docroot         => $grafana_vhost_docroot,
    manage_docroot  => false,  # will be managed by the SSL resource
    redirect_status => 'permanent',
    redirect_dest   => "https://${grafana_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${grafana_vhost_name}_ssl":
    servername           => $grafana_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $grafana_vhost_ssl_protocol,
    ssl_honorcipherorder => $grafana_vhost_ssl_honorcipherorder,
    ssl_cipher           => $grafana_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
    ssl_key              => $ssl_key,
    headers              => [$grafana_vhost_hsts_header],
    docroot              => $grafana_vhost_docroot,
    manage_docroot       => false,
    proxy_pass           => [
      { path => '/',
        url  => $grafana_backend_url,
      },
    ],
    require              => [
        File[$ssl_cert],
        File[$ssl_chain],
        File[$ssl_key],
    ],
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"grafana http redirect on ${::fqdn}":
    service_name  => 'grafana http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $grafana_vhost_name,
      http_vhost   => $grafana_vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"grafana https on ${::fqdn}":
    service_name  => 'grafana https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $grafana_vhost_name,
      http_vhost   => $grafana_vhost_name,
      http_ssl     => true,
      http_sni     => true,
      http_uri     => '/login',
      http_string  => '<title>Grafana</title>',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"grafana https certificate ${::fqdn}":
    service_name  => 'grafana https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $grafana_vhost_name,
      http_vhost       => $grafana_vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
