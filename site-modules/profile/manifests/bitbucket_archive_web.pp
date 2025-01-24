# Deployment of web-facing public Git-bitbucket_archive
class profile::bitbucket_archive_web {

  $vhost_name = lookup('bitbucket_archive::vhost::name')
  $vhost_docroot = lookup('bitbucket_archive::vhost::docroot')
  $vhost_ssl_protocol = lookup('bitbucket_archive::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('bitbucket_archive::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('bitbucket_archive::vhost::ssl_cipher')
  $vhost_hsts_header = lookup('bitbucket_archive::vhost::hsts_header')

  include ::profile::apache::common

  exec {"create ${vhost_docroot}":
    creates => $vhost_docroot,
    command => "mkdir -p ${vhost_docroot}",
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
  }

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => 80,
    docroot         => $vhost_docroot,
    manage_docroot  => false,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  ::profile::letsencrypt::certificate {$vhost_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($vhost_name)

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~>
  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => 443,
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

  ::icinga2::object::service {"bitbucket_archive http redirect on ${::fqdn}":
    service_name  => 'bitbucket_archive http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    export        => [$icinga_checks_hostname]
  }

  ::icinga2::object::service {"bitbucket_archive https on ${::fqdn}":
    service_name  => 'bitbucket_archive https',
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

  ::icinga2::object::service {"bitbucket_archive https certificate ${::fqdn}":
    service_name  => 'bitbucket_archive https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $vhost_name,
      http_vhost       => $vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 25,
    },
    target        => $icinga_checks_file,
    export        => [$icinga_checks_hostname]
  }
}
