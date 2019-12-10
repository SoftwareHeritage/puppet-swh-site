# Configure prometheus-kafka-consumer-group-exporter
class profile::kafka::prometheus_consumer_group_exporter {

  $pkg = 'prometheus-kafka-consumer-group-exporter'
  $defaults_dir = "/etc/defaults/${pkg}"

  package {$pkg:
    ensure => 'installed',
  }

  file {$defaults_dir:
    ensure  => 'directory',
    purge   => true,
    recurse => true,
  }

  $kafka_clusters = lookup('kafka::clusters', Hash)

  $listen_network = lookup('prometheus::kafka_consumer_group::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::kafka_consumer_group::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))

  $base_port = lookup('prometheus::kafka_consumer_group::base_port', Integer)

  $kafka_clusters.keys.each |$index, $cluster| {
    $defaults_file = "${defaults_dir}/${cluster}"
    $service = "${pkg}@${cluster}"

    $bootstrap_servers = $kafka_clusters[$cluster]["brokers"].keys.sort.join(',')
    $port = $base_port + $index

    file {$defaults_file:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profile/kafka/prometheus-kafka-consumer-group-exporter.default.erb'),
    }

    service {$service:
      ensure => 'running',
      enable => true,
      require => [
        File[$defaults_file],
        Package[$pkg],
      ],
    }

    $target = "${actual_listen_address}:${port}"
    profile::prometheus::export_scrape_config {"kafka-consumer-group-${cluster}":
      job    => 'kafka-consumer-group',
      target => $target,
      labels => {
        cluster => $cluster,
      }
    }
  }
}
