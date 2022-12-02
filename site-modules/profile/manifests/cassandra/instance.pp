# Configure a cassandra node on a server
# Several nodes can coexist on a same server
#
# It supposes the profile::cassandra class
# was installed before this
define profile::cassandra::instance (
  $instance_name = $name,
  $config = {}
) {

  $service_name = "cassandra@${instance_name}.service"

  $listen_network = lookup('internal_network')
  $listen_address = ip_for_network($listen_network)

  $cassandra_base_data_dir = lookup('cassandra::base_data_directory')
  $instance_base_data_dir = "${cassandra_base_data_dir}/${instance_name}"
  $cassandra_config_dir = lookup('cassandra::base_config_directory')
  $cassandra_log_dir = lookup('cassandra::base_log_directory')

  $base_data_dir = "${instance_base_data_dir}/data"
  $commitlog_dir = "${instance_base_data_dir}/commitlog"

  $data_dir = "${base_data_dir}/data"
  $hints_dir = "${data_dir}/hints"
  $saved_caches_dir = "${data_dir}/saved_caches"

  $config_dir = "${cassandra_config_dir}/${instance_name}"
  $log_dir = "${cassandra_log_dir}/${instance_name}"

  $jmx_exporter_path = $::profile::prometheus::jmx::jar_path
  $jmx_remote = $config['jmx_remote']
  $jmx_port = $config['jmx_port']

  $heap = $config['heap']

  $base_configuration = lookup('cassandra::base_instance_configuration')
  $instance_configuration = {
    cluster_name           => $config["cluster_name"],
    data_file_directories  => [ $base_data_dir, ],
    commitlog_directory    => $commitlog_dir,
    hints_directory        => $hints_dir,
    saved_caches_directory => $saved_caches_dir,
    listen_address         => $listen_address,
    native_transport_port  => $config['native_transport_port'],
    storage_port           => $config['storage_port'],
    seed_provider          => $config['seed_provider'],
  }

  $computed_configuration = $base_configuration + $instance_configuration

  # jmx port is hardcoded in the cassandra-env.sh file so it needs to be overriden in the
  # service configuration
  if $jmx_remote {
    $extra_jmx_option = "-Dcassandra.jmx.remote.port=${jmx_port} -Dcom.sun.management.jmxremote.access.file=${cassandra_config_dir}/jmxremote.access"
  } else {
    $extra_jmx_option = "-Dcassandra.jmx.local.port=${jmx_port}"
  }

  file {[
      $instance_base_data_dir,
      $base_data_dir,
      # $commitlog_dir,
      $config_dir,
      $log_dir,
    ] :
    ensure  => directory,
    owner   => $::profile::cassandra::cassandra_user,
    group   => $::profile::cassandra::cassandra_group,
    require => [
      # File[$::profile::cassandra::cassandra_base_data_directory],
      # File[$::profile::cassandra::cassandra_config_directory],
      # File[$::profile::cassandra::cassandra_log_directory],
    ]
  }

  ::systemd::dropin_file { "${service_name}.d/parameters.conf":
    ensure   => present,
    unit     => "cassandra@${instance_name}.service",
    filename => 'parameters.conf',
    content  => template('profile/cassandra/instance-parameters.conf.erb'),
  }

  service {$service_name:
    enable => true,
  }

  $config_files_to_copy = [
    'jvm11-server.options',
    'jvm-server.options',
    'logback.xml',
    'cassandra-env.sh',
  ]

  $config_files_to_copy.each | $file_name | {
    file { "${config_dir}/${file_name}":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => "/opt/cassandra/conf/${file_name}",
      require => [File[$config_dir]],
    }
  }

  file { "${config_dir}/cassandra.yaml":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($computed_configuration),
    require => [File[$config_dir]],
  }

  file { "${config_dir}/cassandra-rackdc.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/cassandra/cassandra-rackdc.properties.erb'),
    require => [File[$config_dir]],
  }

}
