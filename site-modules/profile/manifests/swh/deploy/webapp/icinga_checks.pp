class profile::swh::deploy::webapp::icinga_checks {
  $vhost_name = $::profile::swh::deploy::webapp::vhost_name
  $vhost_ssl_port = $::profile::swh::deploy::webapp::vhost_ssl_port
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  $checks = {
    'counters'      => {
      http_uri    => '/api/1/stat/counters/',
      http_string => '"content":',
    },
    'content known' => {
      http_uri    => '/api/1/content/known/search/',
      http_post   => 'q=8624bcdae55baeef00cd11d5dfcfa60f68710a02',
      http_string => '"found":true',
    },
    'content end to end' => {
      http_uri    => '/browse/content/4dfc4478b1d5f7388b298fdfc06802485bdeae0c/',
      http_string => 'PYTHON SOFTWARE FOUNDATION LICENSE VERSION 2',
    },
    'directory end to end' => {
      http_uri               => '/browse/directory/977fc4b98c0e85816348cebd3b12026407c368b6/',
      http_linespan          => true,
      http_expect_body_regex => 'Doc.*Grammar.*Include.*Lib.*Mac.*Misc.*Modules.*Objects.*PC.*PCbuild.*LICENSE.*README.rst',
    },
    'revision end to end' => {
      http_uri               => '/browse/revision/f1b94134a4b879bc55c3dacdb496690c8ebdc03f/',
      http_linespan          => true,
      http_expect_body_regex => join([
        '-:"Allocate the output vlc pictures with dimensions padded,.*',
        'as requested by the decoder \\\\(for alignments\\\\)."'
      ]),
    },
    'revision log end to end' => {
      http_uri               => '/browse/revision/b9b0ecd1e2f9db10335383651f8317ed8cec8296/log/',
      http_linespan          => true,
      http_expect_body_regex => join([
        '-:"',
        join([
          '/browse/revision/b9b0ecd1e2f9db10335383651f8317ed8cec8296/',
          'Roberto Di Cosmo',
          'Moved to github',
        ], '.*'),
        '"',
      ]),
    },
    'release end to end' => {
      http_uri               => '/browse/release/a9b7e3f1eada90250a6b2ab2ef3e0a846cb16831/',
      http_linespan          => true,
      http_expect_body_regex => join([
        '-:"Linux 4.9-rc8.*',
        '/revision/3e5de27e940d00d8d504dfb96625fb654f641509/"'
      ]),
    },
    'snapshot end to end' => {
      http_uri => '/browse/snapshot/baebc2109e4a2ec22a1129a3859647e191d04df4/branches/',
      http_linespan => true,
      http_expect_body_regex => join([
        '-:"',
        join([
          'buster/main/4.13.13-1',
          'buster/main/4.14.12-2',
          'buster/main/4.14.13-1',
          'buster/main/4.14.17-1',
          'buster/main/4.15.4-1',
          'buster/main/4.9.65-3',
          'experimental/main/4.10~rc6-1~exp2',
          'jessie-backports/main/3.16.39-1',
          'jessie-backports/main/4.7.8-1~bpo8\\\\+1',
          'jessie-backports/main/4.9.18-1~bpo8\\\\+1',
          'jessie-backports/main/4.9.65-3\\\\+deb9u1~bpo8\\\\+1',
          'jessie-backports/main/4.9.65-3\\\\+deb9u2~bpo8\\\\+1',
          'jessie-kfreebsd/main/3.16.7-ckt9-2',
          'jessie-proposed-updates/main/3.16.51-3',
          'jessie-proposed-updates/main/3.16.51-3\\\\+deb8u1',
          'jessie-updates/main/3.16.51-3',
          'jessie/main/3.16.43-1',
          'jessie/main/3.16.51-2',
          'jessie/main/3.16.7-ckt2-1',
          'jessie/main/3.16.7-ckt20-1\\\\+deb8u3',
        ], '.*'),
        '"',
      ]),
    }
  }

  each($checks) |$name, $args| {
    @@::icinga2::object::service {"swh-webapp ${name} ${::fqdn}":
      service_name  => "swh webapp ${name}",
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_address => $vhost_name,
        http_vhost   => $vhost_name,
        http_port    => $vhost_ssl_port,
        http_ssl     => true,
      } + $args,
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }

  $origins = lookup('swh::deploy::savecodenow::e2e::origins')
  each($origins) | $entry | {
    @@profile::icinga2::objects::e2e_checks_savecodenow {"End-to-end SaveCodeNow Check - ${entry['name']} with type ${entry['type']} in ${environment}":
      server_webapp => lookup('swh::deploy::savecodenow::e2e::webapp'),
      origin_name   => $entry['name'],
      origin_url    => $entry['origin'],
      origin_type   => $entry['type'],
      environment   => $environment,
      tag           => 'icinga2::exported',
    }
  }
}
