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
      http_uri     => '/api/1/content/known/search/',
      http_post    => 'q=8624bcdae55baeef00cd11d5dfcfa60f68710a02',
      http_string  => '\"found\":true',
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
}
