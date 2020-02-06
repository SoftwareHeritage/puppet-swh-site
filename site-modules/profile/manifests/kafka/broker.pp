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

  $broker_config = $kafka_cluster_config['brokers'][$::swh_hostname['internal_fqdn']]
  $broker_id = $broker_config['id']

  $kafka_config = $base_kafka_config + {
    'zookeeper.connect' => $zookeeper_connect_string,
    'broker.id'         => $broker_id,
  }

  $heap_opts = $kafka_cluster_config['broker::heap_opts']

  $kafka_logdirs = lookup('kafka::logdirs', Array)
  $kafka_logdirs.each |$logdir| {
    file {$logdir:
      ensure  => directory,
      owner   => 'kafka',
      group   => 'kafka',
      mode    => '0750',
    } -> Service['kafka']
  }

  $do_tls = $kafka_cluster_config['tls']

  if $do_tls {
    include ::profile::letsencrypt::host_cert
    $cert_paths = ::profile::letsencrypt::certificate_paths($trusted['certname'])
    # $cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']

    $ks_password = fqdn_rand_string(16, '', lookup('kafka::broker::truststore_seed'))

    $ks_location = '/opt/kafka/config/broker.ks'

    java_ks {'kafka:broker':
      ensure       => latest,
      certificate  => $cert_paths['fullchain'],
      private_key  => $cert_paths['privkey'],
      name         => $trusted['certname'],
      target       => $ks_location,
      password     => $ks_password,
      trustcacerts => true,
    }

    $kafka_tls_config = {
      'ssl.keystore.location'  => $ks_location,
      'ssl.keystore.password'  => $ks_password,
      'listeners'              => join([
        "PLAINTEXT://${swh_hostname['internal_fqdn']}:${kafka_cluster_config['plaintext_port']}",
        "SASL_SSL://${swh_hostname['internal_fqdn']}:${kafka_cluster_config['tls_port']}",
      ], ','),
      'sasl.enabled.mechanisms' => 'SCRAM-SHA-256,SCRAM-SHA-512'
    }

    $jaas_config = '/opt/kafka/config/kafka_broker_jaas.conf'

    file {$jaas_config:
      ensure  => present,
      owner   => 'root',
      group   => 'kafka',
      mode    => '0440',
      content => template('profile/kafka/kafka_broker_jaas.conf.erb'),
      notify  => Service['kafka'],
    }

    $jaas_cli_opts = ["-Djava.security.auth.login.config=${jaas_config}"]

  } else {
    $kafka_tls_config = {
      'listeners' => "PLAINTEXT://${swh_hostname['internal_fqdn']}:${kafka_cluster_config['plaintext_port']}",
    }

    $jaas_cli_opts = []
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
    config       => $kafka_config + $kafka_tls_config,
    opts         => join(["-javaagent:${exporter}=${exporter_port}:${exporter_config}"] + $jaas_cli_opts, ' '),
    limit_nofile => '65536',
    heap_opts    => $heap_opts,
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
    labels => {
      cluster => $kafka_cluster,
    }
  }

  ::profile::cron::d {'kafka-purge-logs':
    command => 'find /var/log/kafka -type f -ctime +60 -exec rm {} \+',
    target  => 'kafka',
    minute  => 'fqdn_rand',
    hour    => 2,
  }

  ::profile::cron::d {'kafka-zip-logs':
    command => 'find /var/log/kafka -type f -not -name *.gz -a -ctime +1 -exec gzip {} \+',
    target  => 'kafka',
    minute  => 'fqdn_rand',
    hour    => 3,
  }
}
