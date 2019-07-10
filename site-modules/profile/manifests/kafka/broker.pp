# Kafka broker profile

class profile::kafka::broker {
  include ::profile::zookeeper

  class {'::kafka':
    mirror_url    => lookup('kafka::mirror_url'),
    version       => lookup('kafka::version'),
    scala_version => lookup('kafka::scala_version'),
  }

  $base_kafka_config = lookup('kafka::broker_config', Hash)

  $zookeeper_chroot = lookup('kafka::zookeeper::chroot')
  $zookeeper_servers = lookup('zookeeper::servers', Hash)
  $zookeeper_port = lookup('zookeeper::client_port', Integer)
  $zookeeper_server_string = join(
    $zookeeper_servers.map |$id, $server| {"${server}:${zookeeper_port}"},
    ','
  )

  $zookeeper_connect_string = "${zookeeper_server_string}${zookeeper_chroot}"

  $broker_id = lookup('kafka::brokers', Hash)[$::swh_hostname['internal_fqdn']]['id']

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

  ::profile::prometheus::export_scrape_config {'kafka':
    target => $target,
  }
}
