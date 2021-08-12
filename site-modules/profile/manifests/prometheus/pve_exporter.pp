class profile::prometheus::pve_exporter {
  $user = lookup('prometheus::pve-exporter::user')
  $password = lookup('prometheus::pve-exporter::password')

  $config_dir = '/etc/pve-exporter'
  $config_file = "${config_dir}/pve-exporter.yml"

  $packages = ['python3-prometheus-pve-exporter'];

  # template uses $user and $password

  file {$config_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  ~> file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('profile/pve-exporter/pve-exporter.yml.erb'),
  }

  package {$packages:
    ensure => 'present',
  }

  # template uses $config_file

  $service_name = 'prometheus-pve-exporter.service'
  ::systemd::unit_file {$service_name:
    ensure  => present,
    content => template("profile/pve-exporter/${service_name}.erb"),
  }
  ~> service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => [
      Package[$packages]
    ],
  }

  $service_port = 9221  # default port for the prometheus pve exporter
  profile::prometheus::export_scrape_config {"pve-exporter_${::fqdn}":
    job          => 'pve-exporter',
    target       => "${::fqdn}:${service_port}",
    scheme       => 'http',
    metrics_path => '/pve',
    params       => {
      target => [ '127.0.0.1' ],
    }
  }
}
