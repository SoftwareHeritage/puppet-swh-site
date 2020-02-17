# Configure the Prometheus server
class profile::prometheus::server {
  include profile::prometheus::base

  $config_dir = '/etc/prometheus'
  $base_config_file = "${config_dir}/prometheus.yml.base"
  $config_file = "${config_dir}/prometheus.yml"
  $defaults_file = '/etc/default/prometheus'

  $scrape_configs_dirname = 'exported-configs'
  $scrape_configs_dir = "${config_dir}/${scrape_configs_dirname}"

  $global_config = lookup('prometheus::server::config::global', Hash)
  $rule_files = []
  $scrape_configs = []
  $remote_read = []
  $remote_write = []
  $alert_relabel_configs = []
  $alertmanagers = []

  $full_config = {
    global         => $global_config,
    rule_files     => $rule_files,
    scrape_configs => $scrape_configs,
    alerting       => {
      alert_relabel_configs => $alert_relabel_configs,
      alertmanagers         => $alertmanagers,
    },
    remote_read    => $remote_read,
    remote_write   => $remote_write,
  }

  $lookup_defaults_config = lookup('prometheus::server::defaults_config', Hash)
  $listen_network = lookup('prometheus::server::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::server::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::server::listen_port')
  $target = "${actual_listen_address}:${listen_port}"

  $defaults_config = deep_merge(
    $lookup_defaults_config,
    {
      web => {
        listen_address => $target,
      },
    }
  )

  profile::prometheus::export_scrape_config {'prometheus':
    target => $target,
  }

  package {'prometheus':
    ensure => present,
    notify => Service['prometheus'],
  }

  service {'prometheus':
    ensure  => 'running',
    enable  => true,
    restart => 'systemctl reload prometheus.service',
    require => [
      Package['prometheus'],
      Exec['update-prometheus-config'],
      File[$defaults_file]
    ],
  }

  file {$base_config_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['prometheus'],
    notify  => Exec['update-prometheus-config'],
    content => inline_yaml($full_config),
  }

  file {$scrape_configs_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['prometheus'],
    recurse => true,
    purge   => true,
    notify  => Exec['update-prometheus-config'],
  }

  $update_prometheus_config = '/usr/local/bin/update-prometheus-config'
  file {$update_prometheus_config:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/prometheus/update-prometheus-config'
  }

  exec {'update-prometheus-config':
    command     => "${update_prometheus_config} ${base_config_file} ${scrape_configs_dir} ${config_file}",
    refreshonly => true,
    require     => [
      File[$base_config_file],
      File[$scrape_configs_dir],
      Package['python3'],
      Package['python3-yaml'],
    ],
    notify => Service['prometheus'],
  }

  # Uses $defaults_config
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/server/prometheus.defaults.erb'),
    require => Package['prometheus'],
    notify  => Service['prometheus'],
  }

  Profile::Prometheus::Scrape_config <<| prometheus_server == $trusted['certname'] |>>
}
