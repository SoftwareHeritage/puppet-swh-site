class profile::swh::deploy::webapp::icinga_checks {
  $vhost_name = $::profile::swh::deploy::webapp::vhost_name
  $vhost_ssl_port = $::profile::swh::deploy::webapp::vhost_ssl_port
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
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

  $activate_check = lookup('swh::deploy::savecodenow::e2e::activate')

  if $activate_check {
     $origins = lookup('swh::deploy::savecodenow::e2e::origins')
     each($origins) | $entry | {
       @@profile::icinga2::objects::e2e_checks_savecodenow {"End-to-end SaveCodeNow Check - ${entry['name']} with type ${entry['type']} in ${environment}":
         server_webapp => lookup('swh::deploy::savecodenow::e2e::webapp'),
         origin_name   => $entry['name'],
         origin_url    => $entry['origin'],
         origin_type   => $entry['type'],
         environment   => $environment,
       }
     }
   }
}
