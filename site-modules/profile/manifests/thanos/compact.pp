# Thanos compact services (compaction and downscaling of historical metrics)
class profile::thanos::compact {
  include profile::thanos::base
  include profile::thanos::objstore_configs

  $internal_ip = ip_for_network(lookup('internal_network'))

  $stores = lookup('thanos::stores')

  $config_dir = $::profile::thanos::base::config_dir
  $stores.each | $dataset_name, $service | {
    $service_name = "thanos-compact@${dataset_name}"
    $unit_name = "${service_name}.service"

    if $service['compact'].get('enabled', true) {
      $port_http = $service['compact']['port-http']
      $http_address = "${internal_ip}:${port_http}"
      $http_target  = "${swh_hostname['internal_fqdn']}:${port_http}"

      ::systemd::dropin_file {"${service_name}/parameters.conf":
        ensure   => present,
        unit     => $unit_name,
        filename => 'parameters.conf',
        content  => template('profile/thanos/compact-parameters.conf.erb'),
        notify   => Service[$service_name],
      }

      service {$service_name:
        ensure  => 'running',
        enable  => true,
        tag     => [
          'thanos',
          'thanos-compact',
          "thanos-objstore-${dataset_name}",
        ],
      }

      ::profile::prometheus::export_scrape_config {"thanos-compact-${http_target}":
        target => $http_target,
        job    => 'thanos_compact',
        labels => {
          dataset_name => $dataset_name,
        },
      }

      $icinga_checks_file = lookup('icinga2::exported_checks::filename')
      $icinga_checks_hostname = lookup('icinga2::exported_checks::hostname')
      $prometheus_server_certname = lookup('prometheus::server::certname')

      ::icinga2::object::service {"thanos compact running (${dataset_name}/${::fqdn})":
        service_name     => "thanos compact running (${dataset_name})",
        import           => ['generic-service'],
        host_name        => $::fqdn,
        check_command    => 'check_prometheus_metric',
        command_endpoint => $prometheus_server_certname,
        vars             => {
          prometheus_metric_name     => "thanos_compact_halted",
          prometheus_query           => profile::icinga2::literal_var(join(['thanos_compact_halted{job="thanos_compact", dataset_name="', $dataset_name,'", instance="', $::fqdn, '"}'])),
          prometheus_query_type      => 'vector',
          prometheus_metric_warning  => '1',
          prometheus_metric_critical => '1',
        },
        target           => $icinga_checks_file,
        export_to        => [$icinga_checks_hostname]
      }

      ::icinga2::object::service {"thanos compact todo (${dataset_name}/${::fqdn})":
        service_name     => "thanos compact todo (${dataset_name})",
        import           => ['generic-service'],
        host_name        => $::fqdn,
        check_command    => 'check_prometheus_metric',
        command_endpoint => $prometheus_server_certname,
        vars             => {
          prometheus_metric_name     => "thanos_compact_todo_compactions",
          prometheus_query           => profile::icinga2::literal_var(join(['thanos_compact_todo_compactions{job="thanos_compact", dataset_name="', $dataset_name,'", instance="', $::fqdn, '"} or vector(0)'])),
          prometheus_query_type      => 'vector',
          prometheus_metric_warning  => '4',
          prometheus_metric_critical => '10',
        },
        target           => $icinga_checks_file,
        export_to        => [$icinga_checks_hostname]
      }

      ::icinga2::object::service {"thanos downsample todo (${dataset_name}/${::fqdn})":
        service_name     => "thanos downsample todo (${dataset_name})",
        import           => ['generic-service'],
        host_name        => $::fqdn,
        check_command    => 'check_prometheus_metric',
        command_endpoint => $prometheus_server_certname,
        vars             => {
          prometheus_metric_name     => "thanos_compact_todo_downsample_blocks",
          prometheus_query           => profile::icinga2::literal_var(join(['sum by (job, dataset_name, instance) (thanos_compact_todo_downsample_blocks{job="thanos_compact", dataset_name="', $dataset_name,'", instance="', $::fqdn, '"}) or vector(0)'])),
          prometheus_query_type      => 'vector',
          prometheus_metric_warning  => '4',
          prometheus_metric_critical => '10',
        },
        target           => $icinga_checks_file,
        export_to        => [$icinga_checks_hostname]
      }
    } else {
      ::systemd::dropin_file {"${service_name}/parameters.conf":
        unit     => $unit_name,
        filename => 'parameters.conf',
        ensure   => absent,
      }

      service {$service_name:
        ensure => 'stopped',
        enable => false,
      }
    }
  }

  # Uses: $config_dir, $cert_paths
  systemd::unit_file {'thanos-compact@.service':
    ensure  => present,
    content => template('profile/thanos/compact@.service.erb'),
    require => Class['profile::thanos::base'],
  } ~> Service <| tag == 'thanos-compact' |>
}
