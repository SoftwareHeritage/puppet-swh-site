# Kafka broker profile

class profile::kafka::broker {
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

  $internal_hostname = $swh_hostname['internal_fqdn']
  $public_hostname = pick($broker_config['public_hostname'], $internal_hostname.regsubst('\.internal', ''))

  $internal_listener = $internal_hostname
  $public_listener_network = pick($kafka_cluster_config['public_listener_network'], lookup('internal_network'))
  $public_listener = ip_for_network($public_listener_network)


  $cluster_config_overrides = pick_default($kafka_cluster_config['cluster_config_overrides'], {})
  $broker_config_overrides = pick_default($broker_config['config_overrides'], {})

  $kafka_config = $base_kafka_config + $cluster_config_overrides + $broker_config_overrides + {
    'zookeeper.connect' => $zookeeper_connect_string,
    'broker.id'         => $broker_id,
  }

  $cluster_superusers = join(
    # broker usernames
    $kafka_cluster_config['brokers'].keys.map |$broker| {"User:broker-${broker}"} +
    pick_default($kafka_cluster_config['superusers'], []),
    ';'
  )

  $heap_opts = $kafka_cluster_config['broker::heap_opts']

  $kafka_logdirs = lookup('kafka::logdirs', Array)
  $kafka_logdirs.each |$logdir| {
    exec {"create ${logdir}":
      creates => $logdir,
      command => "mkdir -p ${logdir}",
      path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    } -> file {$logdir:
      ensure => directory,
      owner  => 'kafka',
      group  => 'kafka',
      mode   => '0750',
    }
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
      require      => Class['Java'],
    }

    $plaintext_port = $kafka_cluster_config['plaintext_port']
    $internal_tls_port = $kafka_cluster_config['internal_tls_port']
    $public_tls_port = $kafka_cluster_config['public_tls_port']

    $sasl_listeners = ['INTERNAL', 'EXTERNAL']
    $sasl_mechanisms = ['SCRAM-SHA-512', 'SCRAM-SHA-256']

    $broker_username = "broker-${::swh_hostname['internal_fqdn']}"
    $broker_password = lookup("kafka::broker::password")

    $kafka_jaas_config = Hash.new(flatten($sasl_listeners.map |$listener| {
      $sasl_mechanisms.map |$mechanism| {
        [
          "listener.name.${listener.downcase}.${mechanism.downcase}.sasl.jaas.config",
          "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"${broker_username}\" password=\"${broker_password}\";",
        ]
      }
    }))

    $kafka_tls_config = {
      'ssl.keystore.location'          => $ks_location,
      'ssl.keystore.password'          => $ks_password,
      'listeners'                      => join([
        "INTERNAL_PLAINTEXT://${internal_listener}:${plaintext_port}",
        "INTERNAL://${internal_listener}:${internal_tls_port}",
        "EXTERNAL://${public_listener}:${public_tls_port}",
      ], ','),
      'advertised.listeners'           => join([
        "INTERNAL_PLAINTEXT://${internal_hostname}:${plaintext_port}",
        "INTERNAL://${internal_hostname}:${internal_tls_port}",
        "EXTERNAL://${public_hostname}:${public_tls_port}",
      ], ','),
      'listener.security.protocol.map' => join([
        'INTERNAL_PLAINTEXT:PLAINTEXT',
        'INTERNAL:SASL_SSL',
        'EXTERNAL:SASL_SSL',
      ], ','),

      'inter.broker.listener.name'     => 'INTERNAL_PLAINTEXT',

      'sasl.enabled.mechanisms'        => join($sasl_mechanisms, ','),

      'super.users'                    => $cluster_superusers,
      'authorizer.class.name'          => 'kafka.security.authorizer.AclAuthorizer',
    } + $kafka_jaas_config

    # Reset the TLS listeners when the keystore gets refreshed
    ['INTERNAL', 'EXTERNAL'].each |$tls_listener_name| {
      Java_ks['kafka:broker']
      ~> exec {"kafka-reload-tls:${tls_listener_name}":
        command     => join([
          '/opt/kafka/bin/kafka-configs.sh',
          '--bootstrap-server', "${internal_hostname}:${plaintext_port}",
          '--entity-name', "${broker_id}",
          '--entity-type', 'brokers',
          '--add-config', "listener.name.${tls_listener_name}.ssl.keystore.location=${ks_location}",
          '--alter',
        ], ' '),
        refreshonly => true,
        require     => Service['kafka'],
      }
    }
  } else {
    $kafka_tls_config = {
      'listeners' => "PLAINTEXT://${internal_hostname}:${kafka_cluster_config['plaintext_port']}",
    }
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
    opts         => join(["-javaagent:${exporter}=${exporter_port}:${exporter_config}"], ' '),
    limit_nofile => '524288',
    heap_opts    => $heap_opts,
    env          => {
      # Deployment options from https://docs.confluent.io/current/kafka/deployment.html
      'KAFKA_JVM_PERFORMANCE_OPTS' => join([
        '-server',
        '-Djava.awt.headless=true',
        '-XX:MetaspaceSize=96m', '-XX:+UseG1GC',
        '-XX:+ExplicitGCInvokesConcurrent', '-XX:MaxGCPauseMillis=20',
        '-XX:InitiatingHeapOccupancyPercent=35', '-XX:G1HeapRegionSize=16M',
        '-XX:MinMetaspaceFreeRatio=50', '-XX:MaxMetaspaceFreeRatio=80',
      ], ' '),
    },
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

  ::systemd::dropin_file {"kafka/killmode.conf":
    ensure   => present,
    unit     => "kafka.service",
    filename => 'killmode.conf',
    content  => "[Service]\nKillMode=mixed\n",
  }

  ::profile::prometheus::export_scrape_config {'kafka':
    target => $target,
    labels => {
      cluster => $kafka_cluster,
    }
  }

  ::profile::cron::d {'kafka-purge-logs':
    command => 'find /var/log/kafka -type f -name *.gz -a -ctime +60 -exec rm {} \+',
    target  => 'kafka',
    minute  => 'fqdn_rand',
    hour    => 2,
  }

  ::profile::cron::d {'kafka-zip-logs':
    command => 'find /var/log/kafka -type f -name *.log.* -a -not -name *.gz -a -not -name *-gc.log* -a -ctime +1 -exec gzip {} \+',
    target  => 'kafka',
    minute  => 'fqdn_rand',
    hour    => 3,
  }
}
