# Reverse proxy to expose staging/admin services
# https://forge.softwareheritage.org/T2747
class profile::swh::deploy::reverse_proxy {
  include ::profile::hitch
  include ::profile::varnish

  $service_names = lookup('swh::deploy::reverse_proxy::services')
  $varnish_http_port = lookup('varnish::http_port')

  each($service_names) |$service_name| {
    # Retrieve certificate name
    $cert_name = lookup("swh::deploy::${service_name}::vhost::letsencrypt_cert")
    $backend_http_host = lookup("swh::deploy::${service_name}::reverse_proxy::backend_http_host")
    $backend_http_port = lookup("swh::deploy::${service_name}::reverse_proxy::backend_http_port")
    $icinga_check_uri = lookup("swh::deploy::${service_name}::icinga_check_uri",
                               default_value => '/')
    $icinga_check_string = lookup("swh::deploy::${service_name}::icinga_check_string",
                                  default_value => capitalize($service_name))

    $websocket_support = lookup({
      'name'          => "swh::deploy::${service_name}::reverse_proxy::websocket_support",
      'default_value' => false,
    })
    $basic_auth = lookup( {
      'name'          => "swh::deploy::${service_name}::reverse_proxy::basic_auth",
      'default_value' => false,
    })
    if $basic_auth {
      $basic_auth_users = lookup( {
        'name'          => "swh::deploy::${service_name}::reverse_proxy::basic_auth::users",
        'default_value' => [],
      })

      $basic_auth_strings = $basic_auth_users.map | $user | {
        $password = lookup("swh::deploy::${service_name}::reverse_proxy::basic_auth::${user}")
        base64('encode', "${user}:${password}", 'strict') # strict to avoid CR at the end of the line
      }
    }

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
      aliases            => $vhost_aliases,
      backend_name       => $service_name,
      backend_http_host  => $backend_http_host,
      backend_http_port  => $backend_http_port,
      hsts_max_age       => lookup('strict_transport_security::max_age'),
      websocket_support  => $websocket_support,
      basic_auth         => $basic_auth,
      basic_auth_strings => $basic_auth_strings,
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
    $authentication_enabled = lookup(
        "swh::deploy::${service_name}::reverse_proxy::basic_auth",
        'default_value' => false,)
    if $authentication_enabled {
      # A real user name can't be specified in http_auth var
      # because the value is exposed in the web ui
      $http_expect_var = { http_expect => '401 Restricted' }
    } else {
      $http_expect_var = {}
    }

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
        http_uri        => $icinga_check_uri,
        http_string     => $icinga_check_string,
        http_onredirect => sticky,
      } + $http_expect_var,
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
