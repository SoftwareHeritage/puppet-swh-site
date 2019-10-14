# Kafka broker profile

class profile::kafka::broker {
  include ::profile::zookeeper
  include ::profile::kafka

  $base_kafka_config = lookup('kafka::broker_config', Hash)

  $kafka_clusters = lookup('kafka::clusters', Hash)

  $kafka_cluster = $kafka_clusters.filter |$cluster, $data| {
    member($data['brokers'].keys(), $::swh_hostname['internal_fqdn'])
  }.keys()[0]

  $kafka_cluster_config = $kafka_clusters[$kafka_cluster]

  $zookeeper_chroot = $kafka_cluster_config['zookeeper::chroot']
  $zookeeper_servers = $kafka_cluster_config['zookeeper::servers']
  $zookeeper_port = lookup('zookeeper::client_port', Integer)
  $zookeeper_server_string = join(
    $zookeeper_servers.map |$server| {"${server}:${zookeeper_port}"},
    ','
  )

  $zookeeper_connect_string = "${zookeeper_server_string}${zookeeper_chroot}"

  $broker_id = $kafka_cluster_config['brokers'][$::swh_hostname['internal_fqdn']]['id']

  $kafka_config = $base_kafka_config + {
    'zookeeper.connect' => $zookeeper_connect_string,
    'broker.id'         => $broker_id
  }

  $kafka_logdirs = lookup('kafka::logdirs', Array)
  $kafka_logdirs.each |$logdir| {
    file {$logdir:
      ensure  => directory,
      owner   => 'kafka',
      group   => 'kafka',
      mode    => '0750',
    } -> Service['kafka']
  }

  include ::profile::prometheus::jmx

  $exporter = $::profile::prometheus::jmx::jar_path

  $exporter_network = lookup('prometheus::kafka::listen_network', Optional[String], 'first', undef)
  $exporter_address = lookup('prometheus::kafka::listen_address', Optional[String], 'first', undef)
  $actual_exporter_address = pick($exporter_address, ip_for_network($exporter_network))
  $exporter_port = lookup('prometheus::kafka::listen_port')
  $target = "${actual_exporter_address}:${exporter_port}"

  $exporter_config = "${::profile::prometheus::jmx::base_directory}/kafka.yml"

  file {$exporter_config:
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profile/kafka/jmx_exporter.yml',
  }

  class {'::kafka::broker':
    config       => $kafka_config,
    opts         => "-javaagent:${exporter}=${exporter_port}:${exporter_config}",
    limit_nofile => '65536',
    require      => [
      File[$exporter],
      File[$exporter_config],
    ],
  }

  ::systemd::dropin_file {"kafka/restart.conf":
    ensure   => present,
    unit     => "kafka.service",
    filename => 'restart.conf',
    content  => "[Service]\nRestart=on-failure\nRestartSec=5\n",
  }

  ::systemd::dropin_file {"kafka/stop-timeout.conf":
    ensure   => present,
    unit     => "kafka.service",
    filename => 'stop-timeout.conf',
    content  => "[Service]\nTimeoutStopSec=infinity\n",
  }

  ::systemd::dropin_file {"kafka/exitcode.conf":
    ensure   => present,
    unit     => "kafka.service",
    filename => 'exitcode.conf',
    content  => "[Service]\nSuccessExitStatus=143\n",
  }

  ::profile::prometheus::export_scrape_config {'kafka':
    target => $target,
  }
}
