class profile::preseeding_vhost {
  $vhost_name = lookup('preseeding::vhost::name')
  $vhost_aliases = lookup('preseeding::vhost::aliases')
  $vhost_docroot = lookup('preseeding::vhost::docroot')
  $vhost_docroot_owner = lookup('preseeding::vhost::docroot::owner')
  $vhost_docroot_group = lookup('preseeding::vhost::docroot::group')
  $vhost_docroot_mode = lookup('preseeding::vhost::docroot::mode')
  $vhost_ssl_protocol = lookup('preseeding::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('preseeding::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('preseeding::vhost::ssl_cipher')

  include ::profile::apache::common

  $directories_config = [
    {
      path    => $vhost_docroot,
      require => 'all granted',
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    },
  ]

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    serveraliases   => $vhost_aliases,
    port            => 80,
    docroot         => $vhost_docroot,
    docroot_owner   => $vhost_docroot_owner,
    docroot_group   => $vhost_docroot_group,
    docroot_mode    => $vhost_docroot_mode,
    manage_docroot  => true,
    directories     => $directories_config,
  }

  ::profile::letsencrypt::certificate {$vhost_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($vhost_name)

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
    docroot              => $vhost_docroot,
    manage_docroot       => false,
    directories          => $directories_config,
    require              => [
      File[$cert_paths['cert']],
      File[$cert_paths['chain']],
      File[$cert_paths['privkey']],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_checks_hostname = lookup('icinga2::exported_checks::hostname')

  ::icinga2::object::service {"preseeding http on ${::fqdn}":
    service_name  => 'preseeding http',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $vhost_name,
      http_vhost      => $vhost_name,
      http_uri        => '/preseed.txt.j2',
    },
    target        => $icinga_checks_file,
    export_to     => [$icinga_checks_hostname]
  }

  ::icinga2::object::service {"preseeding https on ${::fqdn}":
    service_name  => 'preseeding https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $vhost_name,
      http_vhost      => $vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/preseed.txt.j2',
    },
    target        => $icinga_checks_file,
    export_to     => [$icinga_checks_hostname]
  }

  ::icinga2::object::service {"preseeding https certificate ${::fqdn}":
    service_name  => 'preseeding https certificate',
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
    export_to     => [$icinga_checks_hostname]
  }
}
