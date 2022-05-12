# Prometheus configuration for statsd exporter
class profile::prometheus::statsd {
  include profile::prometheus::base

  package {'prometheus-statsd-exporter':
    ensure => 'purged',
    notify => Class['systemd::systemctl::daemon_reload'],
  }

  ::systemd::dropin_file {'prometheus-statsd-exporter/restart.conf':
    ensure   => absent,
    unit     => 'prometheus-statsd-exporter.service',
    filename => 'restart.conf',
  }

  $version = lookup('prometheus::statsd::exporter::version')
  $archive_sha256sum = lookup('prometheus::statsd::exporter::archive_sha256sum')

  $exporter_name = "statsd_exporter"
  $github_project = "prometheus/${exporter_name}"
  $service_name = "prometheus-statsd-exporter"
  $unit_name = "${service_name}.service"

  $url = "https://github.com/${github_project}/releases/download/v${version}/${exporter_name}-${version}.linux-amd64.tar.gz"

  $exporter_dir = "/opt/${service_name}-${version}"
  $exporter_exe = "${exporter_dir}/${exporter_name}"

  file {$exporter_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  -> archive { "/tmp/${exporter_name}.tar.gz":
    source          => $url,
    extract         => true,
    extract_path    => $exporter_dir,
    extract_command => 'tar xfz %s --strip-components=1',
    checksum        => $archive_sha256sum,
    checksum_type   => 'sha256',
    creates         => $exporter_exe,
    cleanup         => true,
  }
  -> file {$exporter_exe:}

  $service_file = '/etc/systemd/system/prometheus-statsd-exporter.service'
  $mapping_config_file = '/etc/prometheus/statsd_exporter_mapping.yml'

  $lookup_defaults_config = lookup('prometheus::statsd::defaults_config', Hash)
  $listen_network = lookup('prometheus::statsd::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::statsd::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $prometheus_listen_port = lookup('prometheus::statsd::listen_port')
  $target = "${actual_listen_address}:${prometheus_listen_port}"

  $listen_tcp = lookup('prometheus::statsd::statsd_listen_tcp')
  $listen_udp = lookup('prometheus::statsd::statsd_listen_udp')

  $mapping_config = lookup('prometheus::statsd::mapping', Hash)


  $defaults_config = deep_merge(
    $lookup_defaults_config,
    {
      web => {
        listen_address => $target,
      },
      statsd => {
        mapping_config => $mapping_config_file,
        listen_tcp => $listen_tcp,
        listen_udp => $listen_udp,
      }
    }
  )

  file {$mapping_config_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($mapping_config),
    notify  => Service[$service_name],
  }

  # uses $exporter_exe and $defaults_config
  ::systemd::unit_file {$unit_name:
    ensure   => present,
    content  => template('profile/prometheus/statsd/prometheus-statsd-exporter.service.erb'),
    require  => [
      File[$exporter_exe],
      File[$mapping_config_file],
    ],
  }

  ~> service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => Class['systemd::systemctl::daemon_reload'],
  }

  profile::prometheus::export_scrape_config {'statsd':
    target => $target,
  }
}
