# Install the base components of a 4.x cassandra server
# Configure all the instances declared in cassandra::instances property
#
# Look at profile::cassandra:node for more information about the
# instance(s) configuration
class profile::cassandra {

  include profile::prometheus::jmx
  $jmx_exporter_version = lookup('prometheus::jmx::version')

  $cassandra_user = 'cassandra'
  $cassandra_group = 'cassandra'
  $cassandra_home = '/home/cassandra'

  $cassandra_version = lookup('cassandra::version')
  $cassandra_archive_name = "apache-cassandra-${cassandra_version}-bin.tar.gz"
  $cassandra_bin_url = "https://dlcdn.apache.org/cassandra/${cassandra_version}/${cassandra_archive_name}"
  $cassandra_bin_checksum_type = 'sha512'
  $cassandra_bin_checksum = '188e131392ea0e48b46f24b1be297ef6335197f4480c9421328006507e069dce659ce3ce473906398273a5926e331960cbf824362e40cb4c74670cde95458349'

  $systemd_service = 'cassandra@.service'

  $download_path = "/opt/${cassandra_archive_name}"

  $cassandra_install_directory = "/opt/cassandra-${cassandra_version}"

  $cassandra_base_data_directory = lookup('cassandra::base_data_directory')
  $cassandra_config_directory = lookup('cassandra::base_config_directory')
  $cassandra_log_directory = lookup('cassandra::base_log_directory')

  $cassandra_nodes = lookup('cassandra::nodes')
  $node_definition = $cassandra_nodes["$::fqdn"]
  $instances = $node_definition['instances']

  $default_instance_config = lookup('cassandra::default_instance_configuration')
  $clusters_config = lookup('cassandra::clusters')

  group {$cassandra_group:
    system => true,
  }

  user {$cassandra_user:
    system => true,
    gid    => $cassandra_group,
    shell  => '/usr/sbin/nologin',
    home   => $cassandra_home,
  }

  file { [
      $cassandra_install_directory,
      $cassandra_config_directory,
    ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  $config_files_to_copy = [
    'jvm11-clients.options',
    'jvm-clients.options',
    'logback-tools.xml',
  ]

  $config_files_to_copy.each | $file_name | {
    file { "${cassandra_config_directory}/${file_name}":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => "/opt/cassandra/conf/${file_name}",
      require => [File[$cassandra_config_directory]],
    }
  }

  file { [
      $cassandra_base_data_directory,
      $cassandra_log_directory,
    ]:
    ensure => directory,
    owner  => $cassandra_user,
    group  => $cassandra_group,
    mode   => '0750'
  }

  ensure_packages(['openjdk-11-jdk', 'libnetty-java'])

  archive { 'cassandra':
    path            => $download_path,
    extract         => true,
    extract_command => 'tar xzf %s --strip-components=1 --no-same-owner --no-same-permissions',
    source          => $cassandra_bin_url,
    extract_path    => $cassandra_install_directory,
    checksum_type   => $cassandra_bin_checksum_type,
    checksum        => $cassandra_bin_checksum,
    creates         => "${cassandra_install_directory}/bin/cassandra",
    cleanup         => true,
    user            => 'root',
    group           => 'root',
    require         => File[$cassandra_install_directory],
  }
  -> file {'/opt/cassandra':
    ensure => link,
    force  => true,
    target => $cassandra_install_directory
  }

  ::systemd::unit_file {$systemd_service:
      ensure  => present,
      content => template('profile/cassandra/cassandra.service.erb'),
  }

  file {"${cassandra_config_directory}/jmx_exporter.yml":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "https://raw.githubusercontent.com/prometheus/jmx_exporter/parent-${jmx_exporter_version}/example_configs/cassandra.yml",
  }

  $instances.each | $instance_name, $instance_config | {
    $merged_instance_config = $default_instance_config + $instance_config
    $cluster_config = $clusters_config[$merged_instance_config["cluster_name"]]
    $merged_config = $cluster_config + $merged_instance_config

    profile::cassandra::instance{$instance_name:
      config => $merged_config
    }
  }

}

