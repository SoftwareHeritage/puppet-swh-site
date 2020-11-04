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

    # icinga alerts
    # @@::icinga2::object::service {"${service_name} http redirect on ${::fqdn}":
    #   service_name  => 'swh webapp http redirect',
    #   import        => ['generic-service'],
    #   host_name     => $::fqdn,
    #   check_command => 'http',
    #   vars          => {
    #     http_address => $vhost_name,
    #     http_vhost   => $vhost_name,
    #     http_port    => $varnish_http_port,
    #     http_uri     => '/',
    #   },
    #   target        => $icinga_checks_file,
    #   tag           => 'icinga2::exported',
    # }
  }
}
