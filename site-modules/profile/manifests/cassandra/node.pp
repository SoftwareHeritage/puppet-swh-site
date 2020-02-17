# Definition of a cassandra node
class profile::cassandra::node {
  include profile::cassandra::apt_config

  $basedir = '/srv/cassandra'
  $commitlogdir = "${basedir}/commitlog"
  $datadir = "${basedir}/data"
  $hintsdir = "${basedir}/hints"

  file {$basedir:
    ensure => 'directory',
    owner  => 'cassandra',
    group  => 'cassandra',
  }

  $baseline_settings = lookup('cassandra::baseline_settings')

  $cluster = lookup('cassandra::cluster')
  $cluster_settings = lookup('cassandra::clusters', Hash)[$cluster]

  $listen_network = lookup('cassandra::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('cassandra::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))

  $listen_settings = {
    listen_address => $actual_listen_address,
    rpc_address    => $actual_listen_address
  }

  $exporter_version = lookup('cassandra::exporter::version')
  $exporter_filename = "cassandra-exporter-agent-${exporter_version}.jar"
  $exporter_url = "https://github.com/instaclustr/cassandra-exporter/releases/download/v${exporter_version}/${exporter_filename}"

  $exporter_base_directory = '/opt/prometheus-cassandra-exporter'
  $exporter_path = "${exporter_base_directory}/${exporter_filename}"
  $exporter_config = "/etc/cassandra/cassandra-exporter.options"

  file {$exporter_base_directory:
    ensure => 'directory',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }

  # Use wget to work around https://tickets.puppetlabs.com/browse/PUP-6380
  exec {"wget --quiet ${exporter_url} -O ${exporter_path}":
    path     => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    creates  => $exporter_path,
    requires => File[$exporter_base_directory],
  }

  $exporter_network = lookup('cassandra::exporter::listen_network', Optional[String], 'first', undef)
  $exporter_address = lookup('cassandra::exporter::listen_address', Optional[String], 'first', undef)
  $actual_exporter_address = pick($exporter_address, ip_for_network($exporter_network))

  $exporter_port = lookup('cassandra::exporter::listen_port')

  $exporter_target = "${actual_exporter_address}:${exporter_port}"

  file {$exporter_config:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    content => template('profile/cassandra/cassandra-exporter.options.erb'),
    notify => Service['cassandra'],
  }

  ::systemd::unit_file {'cassandra.service':
    content => template('profile/cassandra/cassandra.service.erb'),
    notify  => Service['cassandra'],
    require => [
      File[$exporter_path],
      File[$exporter_config],
    ],
  }

  ::profile::prometheus::export_scrape_config {'cassandra':
    target => $exporter_target,
    labels => {
      cluster => $cluster,
    }
  }

  package {'openjdk-8-jre-headless':
    ensure => 'installed',
  }
  -> class {'::cassandra':
    baseline_settings     => $baseline_settings,
    commitlog_directory   => $commitlogdir,
    data_file_directories => [$datadir],
    hints_directory       => $hintsdir,
    settings              => $cluster_settings + $listen_settings,
  }

  file {'/etc/cassandra/jvm.options':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/cassandra/jvm.options',
    require => Package['cassandra'],
    notify  => Service['cassandra'],
  }

  file {'/etc/udev/rules.d/99-cassandra.rules':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/cassandra/99-cassandra.rules',
    notify  => Exec['cassandra-reload-udev-rules'],
  }

  exec {'cassandra-reload-udev-rules':
    command     => 'udevadm control --reload-rules',
    refreshonly => true,
    path        => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  }
}
