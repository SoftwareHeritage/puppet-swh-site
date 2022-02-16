# Journal management scripts
class profile::kafka::management_scripts {
  $clusters = lookup('kafka::clusters')

  $zookeeper_port = lookup('zookeeper::client_port', Integer)

  $clusters.each | $cluster, $config | {

    $script_name = "/usr/local/sbin/manage_kafka_user_${cluster}.sh"
    $kafka_plaintext_port = $config['plaintext_port']
    $zookeeper_chroot = $config['zookeeper::chroot']
    $zookeeper_servers = $config['zookeeper::servers']

    $zookeeper_server_string = join(
      $zookeeper_servers.map |$server| {"${server}:${zookeeper_port}"},
      ','
    )

    $zookeeper_connection_string = "${zookeeper_server_string}${zookeeper_chroot}"

    $brokers_connection_string = join($config['brokers'].map | $broker, $broker_config | {
      "${broker}:${kafka_plaintext_port}" }, ','
    )

    # the template uses
    # - zookeeper_connection_string
    # - brokers_connection_string
    # using an indirection to avoid a parsing bug
    $filename = "/usr/local/sbin/create_kafka_users_${cluster}.sh"
    file { $filename:
      ensure  => 'present',
      content => template('profile/kafka/create_kafka_users.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
    }

  }

}
