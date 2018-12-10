# Deployment of prometheus SQL exporter

class profile::prometheus::sql {
  $exporter_name = 'sql'
  $package_name = "prometheus-${exporter_name}-exporter"
  $service_name = $package_name
  $defaults_file = "/etc/default/${package_name}"
  $config_snippet_dir = "/etc/${package_name}"
  $config_file = "/var/run/postgresql/${package_name}.yml"
  $config_updater = "/usr/bin/update-${package_name}-config"

  package {$package_name:
    ensure => installed,
  }

  service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => [
      Package[$package_name],
    ]
  }

  ::systemd::dropin_file {"${service_name}/restart.conf":
    ensure   => present,
    unit     => "${service_name}.service",
    filename => 'restart.conf',
    content  => "[Service]\nRestart=always\nRestartSec=5\n",
  }

  ::systemd::dropin_file {"${service_name}/update_config.conf":
    ensure   => present,
    unit     => "${service_name}.service",
    filename => 'update_config.conf',
    content  => template('profile/prometheus/sql/systemd/update_config.conf.erb'),
  }

  $update_deps = ['postgresql-client-common', 'libyaml-perl']
  ensure_packages(
    $update_deps, {
      ensure => present
    },
  )

  file {$config_updater:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/prometheus/sql/update-prometheus-sql-exporter-config',
    require => Package[$update_deps],
  }

  file {$config_snippet_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  $config_snippets = lookup('prometheus::sql::config_snippets', Array[String], 'unique')

  each($config_snippets) |$snippet| {
    file {"${config_snippet_dir}/${snippet}.yml":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///modules/profile/prometheus/sql/config/${snippet}.yml",
    }
  }

  $listen_network = lookup('prometheus::sql::listen_network', Optional[String], 'first', undef)
  $listen_ip = lookup('prometheus::sql::listen_address', Optional[String], 'first', undef)
  $actual_listen_ip = pick($listen_ip, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::sql::listen_port')
  $listen_address = "${actual_listen_ip}:${listen_port}"

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
    target => $listen_address,
  }
}
