# Install icinga checks for one webapp instance
define profile::swh::deploy::webapp::icinga_checks (
  # vhost name of the service to check
  $vhost_name       = $title,
  $vhost_ssl_port   = 443,
  $environment      = undef,
  # The hostname where the services runs (icinga needs it)
  $host_name        = undef,
  # Whether we need to create the grape of icinga objects so the check can install
  # properly (should be false for puppet managed services). If true, this requires the
  # $host_name to be provided
  $create_host_name = false,
) {
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

  # By default, it's created by itself by puppet managed nodes. As we start having
  # services not running on nodes managed by puppet (think elastic infra), we need to
  # create fake Host objects (and their deps) to satisfy icinga so we can install checks
  # without icinga being unhappy.
  if $create_host_name and $host_name {
    $icinga2_network = lookup('icinga2::network')
    $hiera_host_vars = lookup('icinga2::host::vars', Hash, 'deep')
    $parent_zone = lookup('icinga2::parent_zone')
    $parent_endpoints = lookup('icinga2::parent_endpoints')

    ::icinga2::object::endpoint {$host_name:
      host   => ip_for_network($icinga2_network),
      target => "/etc/icinga2/zones.d/${parent_zone}/${host_name}.conf",
    }

    ::icinga2::object::zone {$host_name:
      endpoints => [$host_name],
      parent    => $parent_zone,
      target    => "/etc/icinga2/zones.d/${parent_zone}/${host_name}.conf",
    }

    ::icinga2::object::host {$host_name:
      display_name  => $host_name,
      check_command => 'dummy',
      vars          => deep_merge($local_host_vars, $hiera_host_vars),
      target        => "/etc/icinga2/zones.d/${parent_zone}/${host_name}.conf",
    }
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
        tag           => 'icinga2::exported',
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
