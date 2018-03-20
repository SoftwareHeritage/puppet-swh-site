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
  $zookeeper_connect_string = join(
    $zookeeper_servers.map |$id, $server| {"${server}:${zookeeper_port}${zookeeper_chroot}"},
    ','
  )

  $kafka_config = $base_kafka_config + {
    'zookeeper.connect' => $zookeeper_connect_string,
  }

  class {'::kafka::broker':
    config => $kafka_config,
  }
}
