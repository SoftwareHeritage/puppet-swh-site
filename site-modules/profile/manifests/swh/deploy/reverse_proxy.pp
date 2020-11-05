# Reverse proxy to expose staging services
# https://forge.softwareheritage.org/T2747
class profile::swh::deploy::reverse_proxy {
  include ::profile::hitch
  include ::profile::varnish

  $service_names = lookup('swh::deploy::reverse_proxy::services')
  $varnish_http_port = lookup('varnish::http_port')

  each($service_names) |$service_name| {
    # Retrieve certificate name
    $cert_name = lookup("swh::deploy::${service_name}::vhost::letsencrypt_cert")

    # Retrieve the list of vhosts
    $vhosts = lookup('letsencrypt::certificates')[$cert_name]['domains']
    if $swh_hostname['fqdn'] in $vhosts {
      $vhost_name = $swh_hostname['fqdn']
    } else {
      $vhost_name = $vhosts[0]
    }
    # Compute aliases, removing the main vhost from the list
    $vhost_aliases = delete($vhosts, $vhost_name)

    realize(::Profile::Hitch::Ssl_cert[$cert_name])
    ::profile::varnish::vhost {$vhost_name:
      aliases      => $vhost_aliases,
      hsts_max_age => lookup('strict_transport_security::max_age'),
    }

    $icinga_checks_file = lookup('icinga2::exported_checks::filename')

    # icinga alerts
    @@::icinga2::object::service {"${service_name} http redirect on ${::fqdn}":
      service_name  => "swh ${service_name} http redirect",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_address => $vhost_name,
        http_vhost   => $vhost_name,
        http_port    => $varnish_http_port,
        http_uri     => '/',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }

    $vhost_ssl_port = lookup('apache::https_port')

    # $vhost_ssl_protocol = lookup('swh::deploy::webapp::vhost::ssl_protocol')
    # $vhost_ssl_honorcipherorder = lookup('swh::deploy::webapp::vhost::ssl_honorcipherorder')
    # $vhost_ssl_cipher = lookup('swh::deploy::webapp::vhost::ssl_cipher')

    @@::icinga2::object::service {"swh-${service_name} https on ${::fqdn}":
      service_name  => "swh ${service_name}",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_address    => $vhost_name,
        http_vhost      => $vhost_name,
        http_port       => $vhost_ssl_port,
        http_ssl        => true,
        http_sni        => true,
        http_uri        => '/',
        http_onredirect => sticky
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }

    @@::icinga2::object::service {"swh-${service_name} https certificate ${::fqdn}":
      service_name  => "swh ${service_name} https certificate",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_address     => $vhost_name,
        http_vhost       => $vhost_name,
        http_port        => $vhost_ssl_port,
        http_ssl         => true,
        http_sni         => true,
        http_certificate => 15,
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
