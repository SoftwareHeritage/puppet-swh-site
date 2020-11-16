# Configure the icinga checks and prometheus endpoints for the firewalls
class profile::opnsense::monitoring {
  $fw_hosts = lookup('opnsense::hosts')
  $fw_prometheus_port = lookup('opnsense::prometheus::port')
  $fw_prometheus_metrics_path = lookup('opnsense::prometheus::metrics_path')

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_zonename = lookup('icinga2::master::zonename')

  $fw_hosts.each | $host | {

    $target = "${host}:${fw_prometheus_port}"

    profile::prometheus::export_scrape_config { $host :
      target       => $target,
      scheme       => 'http',
      metrics_path => $fw_prometheus_metrics_path,
    }

    ::icinga2::object::host {$host:
      display_name  => $host,
      check_command => 'hostalive',
      target        => "/etc/icinga2/zones.d/${icinga_zonename}/${host}.conf",
    }

    ::icinga2::object::service {"opnsense https on ${host}":
      service_name  => 'opnsense',
      import        => ['generic-service'],
      host_name     => $host,
      check_command => 'http',
      vars          => {
        http_address    => $host,
        http_vhost      => $host,
        http_ssl        => true,
        http_uri        => '/',
        http_onredirect => sticky
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
