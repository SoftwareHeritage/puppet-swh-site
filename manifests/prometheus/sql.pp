# Deployment of prometheus SQL exporter

class profile::prometheus::sql {
  package {'prometheus-sql-exporter':
    ensure => latest,
  }

  service {'prometheus-sql-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-sql-exporter'],
      File['/etc/defaults/prometheus-sql-exporter'],
      Exec['/usr/bin/update-prometheus-sql-exporter-config'],
    ]
  }


  file {'/usr/bin/update-prometheus-sql-exporter-config':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/profile/prometheus/sql/update-prometheus-sql-exporter-config',
  }

  file {'/etc/prometheus/prometheus-sql-exporter.yml.in':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/sql/prometheus-sql-exporter.yml.in.erb'),
    notify  => Exec['/usr/bin/update-prometheus-sql-exporter-config'],
  }

  $update_deps = ['python3-pkg-resources', 'python3-yaml']
  ensure_packages(
    $update_deps, {
      ensure => present
    },
  )

  exec {'/usr/bin/update-prometheus-sql-exporter-config':
    refreshonly => true,
    creates     => '/etc/prometheus/prometheus-sql-exporter.yml',
    require     => [
      Package[$update_deps],
      File['/usr/bin/update-prometheus-sql-exporter-config'],
    ],
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

  file {'/etc/defaults/prometheus-sql-exporter':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/sql/prometheus-sql-exporter.defaults.erb'),
    require => Package['prometheus-sql-exporter'],
    notify  => Service['prometheus-sql-exporter'],
  }

  profile::prometheus::export_scrape_config {'sql':
    target => $target,
  }
}
