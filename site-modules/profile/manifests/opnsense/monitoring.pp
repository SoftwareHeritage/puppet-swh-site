# Configure the icinga checks and prometheus endpoints for the firewalls
class profile::opnsense::monitoring {
  $fw_hosts = lookup('opnsense::hosts')
  $fw_prometheus_port = lookup('opnsense::prometheus::port')
  $fw_prometheus_metrics_path = lookup('opnsense::prometheus::metrics_path')

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_zonename = lookup('icinga2::master::zonename')

  $fw_hosts.each | $host, $config | {
    $fqdn = $config['fqdn']
    $ip = $config['ip']

    $target = "${fqdn}:${fw_prometheus_port}"

    $prometheus_labels = {
      'instance' => $fqdn, # override the instance name to use the fw name instead of pergamon
    }

    profile::prometheus::export_scrape_config { "firewall_${fqdn}" :
      job          => 'firewall',
      target       => $target,
      scheme       => 'http',
      metrics_path => $fw_prometheus_metrics_path,
      labels       => $prometheus_labels,
    }

    ::icinga2::object::host {$fqdn:
      display_name  => $fqdn,
      check_command => 'hostalive',
      address       => $ip,
      target        => "/etc/icinga2/zones.d/${icinga_zonename}/${fqdn}.conf",
    }

    ::icinga2::object::service {"opnsense https on ${fqdn}":
      service_name  => 'opnsense',
      import        => ['generic-service'],
      host_name     => $fqdn,
      check_command => 'http',
      vars          => {
        http_address    => $fqdn,
        http_vhost      => $fqdn,
        http_ssl        => true,
        http_uri        => '/',
        http_onredirect => sticky
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
