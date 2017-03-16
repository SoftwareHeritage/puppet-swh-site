# Static checks on the icinga master
class profile::icinga2::objects::static_checks {

  $checks_file = '/etc/icinga2/conf.d/static-checks.conf'

  ::icinga2::object::host {'www.softwareheritage.org':
    import  => ['generic-host'],
    address => 'www.softwareheritage.org',
    target  => $checks_file,
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
}
