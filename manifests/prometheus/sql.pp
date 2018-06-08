# Deployment of prometheus SQL exporter

class profile::prometheus::sql {
  $exporter_name = 'sql'
  $package_name = "prometheus-${exporter_name}-exporter"
  $service_name = $package_name
  $defaults_file = "/etc/default/${package_name}"
  $config_file = "/etc/${package_name}.yml"
  $config_template = "${config_file}.in"
  $config_updater = "/usr/bin/update-${package_name}-config"

  package {$package_name:
    ensure => latest,
  }

  service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => [
      Package[$package_name],
      Exec[$config_updater],
    ]
  }


  file {$config_updater:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/prometheus/sql/update-prometheus-sql-exporter-config',
  }

  # needed for the the configuration generation
  # optiona extra configuration per host
  $extra_config = lookup('prometheus::sql::exporter::extra_config', Data, 'first', undef)

  file {$config_template:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/sql/prometheus-sql-exporter.yml.in.erb'),
    notify  => Exec[$config_updater],
  }

  $update_deps = ['python3-pkg-resources', 'python3-yaml']
  ensure_packages(
    $update_deps, {
      ensure => present
    },
  )

  exec {$config_updater:
    refreshonly => true,
    creates     => $config_file,
    require     => [
      Package[$update_deps],
      File[$config_template],
      File[$config_updater],
    ],
    notify      => Service[$service_name],
  }

  $listen_network = lookup('prometheus::sql::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::sql::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::sql::listen_port')
  $target = "${actual_listen_address}:${listen_port}"

  $defaults_config = {
    web => {
      listen_address => $target,
    },
  }

  file {$defaults_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/sql/prometheus-sql-exporter.defaults.erb'),
    require => Package[$package_name],
    notify  => Service[$service_name],
  }

  profile::prometheus::export_scrape_config {'sql':
    target => $target,
  }
}
