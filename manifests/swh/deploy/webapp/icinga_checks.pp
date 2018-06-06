class profile::swh::deploy::webapp::icinga_checks {
  $vhost_name = $::profile::swh::deploy::webapp::vhost_name
  $vhost_ssl_port = $::profile::swh::deploy::webapp::vhost_ssl_port
  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  $checks = {
    'counters'      => {
      http_uri    => '/api/1/stat/counters/',
      http_string => '\"content\":',
    },
    'content known' => {
      http_uri    => '/api/1/content/known/search/',
      http_post   => 'q=8624bcdae55baeef00cd11d5dfcfa60f68710a02',
      http_string => '\"found\":true',
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
      http_expect_body_regex => '-:"Allocate the output vlc pictures with dimensions padded,.*as requested by the decoder \(for alignments\)."',
    },
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
}
