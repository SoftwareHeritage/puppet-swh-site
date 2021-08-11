class profile::prometheus::pve_exporter {
  $user = lookup('prometheus::pve-exporter::user')
  $password = lookup('prometheus::pve-exporter::password')

  $config_dir = '/etc/pve-exporter'
  $config_file = "${config_dir}/pve-exporter.yml"

  $packages = ['python3-prometheus-pve-exporter'];

  file { $config_dir:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  # template uses $user and $password

  file { $config_file:
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
  file {$service_name:
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    content => template("profile/pve-exporter/${service_name}.erb"),
  }

}
