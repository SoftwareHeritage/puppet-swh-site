# Static checks on the icinga master
class profile::icinga2::objects::static_checks {

  $checks_file = '/etc/icinga2/conf.d/static-checks.conf'

  ::icinga2::object::host {'www.softwareheritage.org':
    import        => ['generic-host'],
    check_command => 'hostalive4',
    address       => 'www.softwareheritage.org',
    target        => $checks_file,
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

  ::icinga2::object::host {'swh-logging-prod':
    check_command => 'hostalive4',
    address       => '127.0.0.1',
    target        => $checks_file,
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

}
