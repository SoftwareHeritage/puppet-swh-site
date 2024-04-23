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

  ::profile::swh::deploy::webapp::icinga_checks {'archive.softwareheritage.org':
    environment => "production",
    host_name   => "moma.softwareheritage.org",
  }

  ::icinga2::object::host {'archive-production-rke2':
    check_command => 'dummy',
    address       => 'k8s-archive-production-rke2.internal.softwareheritage.org',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "Virtual host for icinga checks related to production services",
      noping      => true,
    },
  }

  ::icinga2::object::host {'archive-staging-rke2':
    check_command => 'dummy',
    address       => 'k8s-archive-staging-rke2.internal.staging.swh.network',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "Virtual host for icinga checks related to staging services",
      noping      => true,
    },
  }

  ::profile::swh::deploy::webapp::icinga_checks {'webapp.staging.swh.network':
    environment      => "staging",
    host_name        => "archive-staging-rke2",
  }

  ::profile::swh::deploy::deposit::icinga_checks {'deposit.softwareheritage.org':
    environment => "production",
    host_name   => "moma.softwareheritage.org",
  }

  ::profile::swh::deploy::deposit::icinga_checks {'deposit.staging.swh.network':
    environment      => "staging",
    host_name        => "archive-staging-rke2",
  }

  ::profile::swh::deploy::vault::icinga_checks {'production':
    storage     => "http://storage-postgresql-ro.internal.softwareheritage.org",
    webapp      => "https://archive.softwareheritage.org",
  }

  ::profile::swh::deploy::vault::icinga_checks {'staging':
    storage     => "http://storage-ro.internal.staging.swh.network",
    webapp      => "https://webapp.staging.swh.network",
  }

  ::icinga2::object::host {'Admin Kubernetes cluster':
    import        => ['generic-host'],
    host_name     => 'k8s-admin-rke2.internal.admin.swh.network',
    check_command => 'dummy',
    address       => 'k8s-admin-rke2.internal.admin.swh.network',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => 'HTTP-only host',
      noping      => true,
    },
  }

  ::icinga2::object::host {'Gitlab - production':
    import        => ['generic-host'],
    host_name     => 'gitlab.softwareheritage.org',
    check_command => 'dummy',
    address       => 'gitlab.softwareheritage.org',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => 'HTTP-only host',
      noping      => true,
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

  ::icinga2::object::host {'swh-journal-client-production':
    check_command => 'dummy',
    address       => '127.0.0.1',
    target        => $checks_file,
    vars          => {
      dummy_state => 0,  # up
      dummy_text  => "virtual host for journal client checks in production",
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
  ['massmoca'].each |$replica| {
    ::icinga2::object::service {"Postgresql replication lag (belvedere -> ${replica})":
      check_command => 'check_prometheus_metric',
      target        => $checks_file,
      host_name     => 'albertina.internal.softwareheritage.org',
      vars          => {
        prometheus_metric_name     => "pg replication_lag albertina ${replica}",
        prometheus_query           => profile::icinga2::literal_var(
          join(['sum(sql_pg_stat_replication{instance="albertina.internal.softwareheritage.org", host=":5433", application_name="softwareheritage_replica", slot_name="softwareheritage_', $replica, '"})'], '')
        ),
        prometheus_query_type      => 'vector',
        prometheus_metric_warning  => '1073741824', # 1GiB 1*1024*1024*1024
        prometheus_metric_critical => '2147483648', # 2GiB 2*1024*1024*1024
      },
    }
  }

  $days_2 = 172800  # seconds, twice the max period for incremental listing + 1 day
  $days_3 = 259200  # seconds, twice the max period for incremental listing + 2 days
  $days_8 = 691200  # seconds, intermediary recurring period for full listing + 1 day
  $days_9 = 777600  # seconds, intermediary recurring period for full listing + 2 days
  $days_91 = 7862400  # seconds, max recurring period for full listing + 1 day
  $days_92 = 7948800  # seconds, max recurring period for full listing + 2 days

  [['staging', 'db1.internal.staging.swh.network'],
   ['production', 'albertina.internal.softwareheritage.org']
  ].each |$env_config| {
    $env = $env_config[0]
    $db_host = $env_config[1]

    [['1 day', $days_2, $days_3],
     ['7 days', $days_8, $days_9],
     ['90 days', $days_91, $days_92]
    ].each | $periodic_data | {
       $interval = $periodic_data[0]
       $threshold_warning = $periodic_data[1]
       $threshold_critical = $periodic_data[2]

       ::icinga2::object::service {"${env} - Scheduler recurrent lister tasks with period ${interval} check":
         check_command => 'check_prometheus_metric',
         target        => $checks_file,
         host_name     => $db_host,
         vars          => {
           prometheus_metric_name     => "Scheduler recurrent lister tasks with period ${interval} are stale in ${env}",
           prometheus_query           => profile::icinga2::literal_var(
             join(['histogram_quantile(0.1, sum(sql_swh_scheduler_delay{environment="', $env, '"',
                   ', policy="recurring", current_interval="', $interval, '"',
                   ', status="next_run_scheduled"}) by (le)) or vector(1)'], '')),
               # or vector(1) is a fallback for the case where no data is returned
               # ('null' value). This is considered a success and we're moving along.
          prometheus_query_type      => 'vector',
          prometheus_metric_warning  => $threshold_warning,
          prometheus_metric_critical => $threshold_critical,
        }
      }
    }
  }

  ['swh.scheduler.journal_client',
   'swh.search.journal_client-v0.11',
   'swh.counters.journal_client',
   'swh-archive-prod-webhooks'].each |$consumer_group| {
    ::icinga2::object::service {"Kafka ${consumer_group} lag in production":
      check_command => 'check_prometheus_metric',
      target        => $checks_file,
      host_name     => 'swh-journal-client-production',
      vars          => {
        prometheus_metric_name     => "kafka ${consumer_group} lag",
        prometheus_query           => profile::icinga2::literal_var(
          join(['sum(kafka_consumer_group_lag{group=~"', $consumer_group ,'",environment="production"})'], '')),
        prometheus_query_type      => 'vector',
        prometheus_metric_warning  => '10000',
        prometheus_metric_critical => '20000',
      },
    }
}

  ['swh.scheduler.journal_client',
   'swh.search.journal_client-v0.11',
   'swh.search.journal_client.indexed-v0.11',
   'swh-archive-stg-webhooks',
   'swh.counters.journal_client'].each |$consumer_group| {
    ::icinga2::object::service {"Kafka ${consumer_group} lag in staging":
      check_command => 'check_prometheus_metric',
      target        => $checks_file,
      host_name     => 'archive-staging-rke2',
      vars          => {
        prometheus_metric_name     => "kafka ${consumer_group} lag",
        prometheus_query           => profile::icinga2::literal_var(
          join(['sum(kafka_consumer_group_lag{group=~"', $consumer_group ,'",environment="staging"})'], '')),
        prometheus_query_type      => 'vector',
        prometheus_metric_warning  => '10000',
        prometheus_metric_critical => '20000',
      },
    }
}

  ::icinga2::object::service {'Software Heritage ArgoCD Instance':
    import        => ['generic-service'],
    host_name     => 'k8s-admin-rke2.internal.admin.swh.network',
    check_command => 'http',
    target        => $checks_file,
    vars          => {
      http_vhost  => 'argocd.internal.admin.swh.network',
      http_uri    => '/',
      http_ssl    => true,
      http_sni    => true,
      http_string => '<title>Argo CD</title>',
    },
  }

  $gitlab_vhost = 'gitlab.softwareheritage.org'
  ::icinga2::object::service {'Production gitlab instance - HTTPS':
    import        => ['generic-service'],
    host_name     => $gitlab_vhost,
    check_command => 'http',
    target        => $checks_file,
    vars          => {
      http_vhost      => $gitlab_vhost,
      http_uri        => '/',
      http_ssl        => true,
      http_sni        => true,
      http_onredirect => 'follow',
      http_string     => 'Explore projects',
    },
  }

  ::icinga2::object::service {'Gitlab production https certificate':
    import        => ['generic-service'],
    host_name     => $gitlab_vhost,
    check_command => 'http',
    target        => $checks_file,
    vars          => {
      http_vhost       => $gitlab_vhost,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 7,
    },
  }

  ::icinga2::object::service {'Production gitlab instance - SSH':
    import        => ['generic-service'],
    host_name     => $gitlab_vhost,
    check_command => 'ssh',
    target        => $checks_file,
    vars          => {
      ssh_address => $gitlab_vhost,
    },
  }

  $hosts_to_check_per_environment = {
    # env     => hosts to check as dict
    'staging' => {
      # host              => msg to check in body
      'storage-cassandra' => 'storage server',
      'storage-ro'        => 'storage server',
      'objstorage-ro'     => 'Objstorage API server',
      'counters'          => 'Counters API',
      'search'            => 'Search API',
    },
    'production' => {

    },
  }

  # Install static checks according to environment
  $hosts_to_check_per_environment.each | $env, $hosts_to_check | {
    $hosts_to_check.each | $domain, $msg | {
      if ( $env == 'staging' ) {
        $host = "${domain}.internal.staging.swh.network"
      } else {
        $host = "${domain}.internal.softwareheritage.org"
      }
      $host_name = "archive-${env}-rke2"
      ::icinga2::object::service {"${env} - Host ${host} Check":
        import        => ['generic-service'],
        host_name     => $host_name,
        check_command => 'http',
        target        => $checks_file,
        vars          => {
          http_vhost  => $host,
          http_uri    => '/',
          http_string => $msg,
        },
      }
    }
  }

}
