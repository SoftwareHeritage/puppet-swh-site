# Static checks on the icinga master
class profile::icinga2::objects::static_checks {

  $checks_file = '/etc/icinga2/conf.d/static-checks.conf'

  ::icinga2::object::host {'www.softwareheritage.org':
    import        => ['generic-host'],
    check_command => 'dummy',
    address       => 'www.softwareheritage.org',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "HTTP-only host",
    },
  }

  ::icinga2::object::host {'softwareheritage.org':
    import        => ['generic-host'],
    check_command => 'dummy',
    address       => 'softwareheritage.org',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "HTTP-only host",
    },
  }

  ::icinga2::object::host {'graphql.staging.swh.network':
    import        => ['generic-host'],
    check_command => 'dummy',
    address       => 'graphql.staging.swh.network',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "HTTP-only host",
    },
  }

  ::icinga2::object::service {'Software Heritage Homepage':
    import        => ['generic-service'],
    host_name     => 'www.softwareheritage.org',
    check_command => 'http',
    target        => $checks_file,
    vars          => {
      http_vhost  => 'www.softwareheritage.org',
      http_uri    => '/',
      http_ssl    => true,
      http_sni    => true,
      http_string => '<title>Software Heritage</title>',
    },
  }

  ::icinga2::object::service {'Software Heritage Homepage (redirect to www)':
    import        => ['generic-service'],
    host_name     => 'softwareheritage.org',
    check_command => 'http',
    target        => $checks_file,
    vars          => {
      http_vhost  => 'softwareheritage.org',
      http_uri    => '/',
      http_ssl    => true,
      http_sni    => true,
    },
  }

  ::icinga2::object::host {'swh-logging-prod':
    check_command => 'dummy',
    address       => '127.0.0.1',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "virtual host for clustered checks",
    },
  }

  ::icinga2::object::service {'swh-logging-prod cluster':
    host_name     => 'swh-logging-prod',
    check_command => 'check_escluster',
    target        => $checks_file,
  }

  ::icinga2::object::checkcommand {'check_escluster':
    import        => ['plugin-check-command'],
    command       => '/usr/lib/nagios/plugins/icinga_check_elasticsearch.sh',
    target        => $checks_file,
  }

  ::icinga2::object::host {'DNS resolvers':
    check_command => 'dummy',
    address       => '127.0.0.1',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "virtual host for clustered checks",
    },
  }

  ::icinga2::object::service {'SOA':
    host_name     => 'DNS resolvers',
    check_command => 'check_resolvers',
    target        => $checks_file,
  }

  ::icinga2::object::checkcommand {'check_resolvers':
    import        => ['plugin-check-command'],
    command       => [
	'/usr/lib/nagios/plugins/dsa-nagios-checks_checks_dsa-check-soas.txt',
	'internal.softwareheritage.org',
    ],
    target        => $checks_file,
  }

  $prometheus_host = lookup('prometheus::server::fqdn')
  ::icinga2::object::service {'Postgresql replication lag (belvedere -> somerset)':
    check_command => 'check_prometheus_metric',
    target        => $checks_file,
    host_name     => 'belvedere.internal.softwareheritage.org',
    vars          => {
      prometheus_metric_name     => 'pg replication_lag belvedere somerset',
      prometheus_query           => profile::icinga2::literal_var(
        'sum(sql_pg_stat_replication{instance="belvedere.internal.softwareheritage.org", host=":5433", application_name="softwareheritage_replica"})'
      ),
      prometheus_query_type      => 'vector',
      prometheus_metric_warning  => '1073741824', # 1GiB 1*1024*1024*1024
      prometheus_metric_critical => '2147483648', # 2GiB 2*1024*1024*1024
    },
  }

  ::icinga2::object::service {'Software Heritage Staging Graphql Instance':
    import        => ['generic-service'],
    host_name     => 'graphql.staging.swh.network',
    check_command => 'http',
    target        => $checks_file,
    vars          => {
      http_vhost  => 'graphql.staging.swh.network',
      http_uri    => '/',
      http_ssl    => true,
      http_sni    => true,
      http_string => '<title>GraphQL Playground</title>',
    },
  }

}
