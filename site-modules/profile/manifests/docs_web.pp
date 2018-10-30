# Deployment of web-facing static documentation
class profile::docs_web {

  $docs_basepath =  lookup('docs::basepath')

  $docs_vhost_name = lookup('docs::vhost::name')
  $docs_vhost_docroot = lookup('docs::vhost::docroot')
  $docs_vhost_docroot_owner = lookup('docs::vhost::docroot_owner')
  $docs_vhost_docroot_group = lookup('docs::vhost::docroot_group')
  $docs_vhost_docroot_mode = lookup('docs::vhost::docroot_mode')
  $docs_vhost_ssl_protocol = lookup('docs::vhost::ssl_protocol')
  $docs_vhost_ssl_honorcipherorder = lookup('docs::vhost::ssl_honorcipherorder')
  $docs_vhost_ssl_cipher = lookup('docs::vhost::ssl_cipher')
  $docs_vhost_hsts_header = lookup('docs::vhost::hsts_header')

  include ::profile::ssl
  include ::profile::apache::common

  ::apache::vhost {"${docs_vhost_name}_non-ssl":
    servername      => $docs_vhost_name,
    port            => '80',
    docroot         => $docs_vhost_docroot,
    manage_docroot  => false,  # will be managed by the SSL resource
    redirect_status => 'permanent',
    redirect_dest   => "https://${docs_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${docs_vhost_name}_ssl":
    servername           => $docs_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $docs_vhost_ssl_protocol,
    ssl_honorcipherorder => $docs_vhost_ssl_honorcipherorder,
    ssl_cipher           => $docs_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
    ssl_key              => $ssl_key,
    headers              => [$docs_vhost_hsts_header],
    docroot              => $docs_vhost_docroot,
    docroot_owner        => $docs_vhost_docroot_owner,
    docroot_group        => $docs_vhost_docroot_group,
    docroot_mode         => $docs_vhost_docroot_mode,
    directories          => [{
                             'path'     => $docs_vhost_docroot,
                             'require'  => 'all granted',
                             'options'  => ['Indexes', 'FollowSymLinks', 'MultiViews'],
                             }],
    require              => [
        File[$ssl_cert],
        File[$ssl_chain],
        File[$ssl_key],
    ],
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"docs http redirect on ${::fqdn}":
    service_name  => 'docs http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $docs_vhost_name,
      http_vhost   => $docs_vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"docs https on ${::fqdn}":
    service_name  => 'docs https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $docs_vhost_name,
      http_vhost      => $docs_vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"docs https certificate ${::fqdn}":
    service_name  => 'docs https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $docs_vhost_name,
      http_vhost       => $docs_vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
