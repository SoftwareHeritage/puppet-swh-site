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

  include ::profile::apache::common

  exec {"create ${docs_vhost_docroot}":
    creates => $docs_vhost_docroot,
    command => "mkdir -p ${docs_vhost_docroot}",
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
  }

  ::apache::vhost {"${docs_vhost_name}_non-ssl":
    servername      => $docs_vhost_name,
    port            => '80',
    docroot         => $docs_vhost_docroot,
    manage_docroot  => false,  # will be managed by the SSL resource
    redirect_status => 'permanent',
    redirect_dest   => "https://${docs_vhost_name}/",
  }

  ::profile::letsencrypt::certificate {$docs_vhost_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($docs_vhost_name)

  ::apache::vhost {"${docs_vhost_name}_ssl":
    servername           => $docs_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $docs_vhost_ssl_protocol,
    ssl_honorcipherorder => $docs_vhost_ssl_honorcipherorder,
    ssl_cipher           => $docs_vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
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
    rewrites => [
        { rewrite_rule => '^/?$ /devel/ [R,L]' },
    ],
      require              => [
        File[$cert_paths['cert']],
        File[$cert_paths['chain']],
        File[$cert_paths['privkey']],
      ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

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
      http_certificate => 25,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
