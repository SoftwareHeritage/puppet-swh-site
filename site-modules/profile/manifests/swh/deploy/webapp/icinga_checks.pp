# Install icinga checks for one webapp instance
define profile::swh::deploy::webapp::icinga_checks (
  # vhost name of the service to check
  $vhost_name       = $title,
  $vhost_ssl_port   = 443,
  $environment      = undef,
  # The hostname where the services runs (icinga needs it)
  $host_name        = undef,
) {
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_checks_hostname = lookup('icinga2::exported_checks::hostname')
  $icinga_checks = lookup('swh::deploy::webapp::icinga_checks')

  # so far 3 types of icinga checks (get, post, and regexp). Walk through them and
  # create the expected icinga checks out of those

  $checks_get = $icinga_checks['get'].map | $name, $entry | {
    {
      $name  => {
        http_uri => $entry['uri'],
        http_string => $entry['string'],
      }
    }
  }

  $checks_post = $icinga_checks['post'].map | $name, $entry | {
    {
      $name  => {
        http_uri => $entry['uri'],
        http_post => $entry['post'],
        http_string => $entry['string'],
      }
    }
  }

  $checks_regexp = $icinga_checks['regexp'].map | $name, $entry | {
    {
      $name  => {
        http_uri => $entry['uri'],
        http_linespan => true,
        http_expect_body_regex => join(['-:"'] + $entry['regexp'] + ['"']),
      }
    }
  }

  # compulse checks as one dict
  $checks = ($checks_get + $checks_post + $checks_regexp).reduce({}) |$acc, $entry| {
    merge($acc, $entry)
  }

  each($checks) |$name, $args| {
    ::icinga2::object::service {"swh-webapp ${name} for ${vhost_name}":
      service_name  => "swh webapp ${name} for ${vhost_name}",
      import        => ['generic-service'],
      host_name     => $host_name,
      check_command => 'http',
      vars          => {
        http_address => $vhost_name,
        http_vhost   => $vhost_name,
        http_port    => $vhost_ssl_port,
        http_ssl     => true,
      } + $args,
        target        => $icinga_checks_file,
        export        => [$icinga_checks_hostname]
    }
  }

  $activate_check = lookup('swh::deploy::savecodenow::e2e::activate')

  if $activate_check {
    $origins = lookup('swh::deploy::savecodenow::e2e::origins')
    each($origins) | $entry | {
      profile::icinga2::objects::e2e_checks_savecodenow {"End-to-end SaveCodeNow Check - ${entry['name']} with type ${entry['type']} in ${environment}":
        server_webapp => lookup('swh::deploy::savecodenow::e2e::webapp'),
        origin_name   => $entry['name'],
        origin_url    => $entry['origin'],
        origin_type   => $entry['type'],
        environment   => $environment,
      }
    }
  }
}
