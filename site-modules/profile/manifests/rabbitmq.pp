class profile::rabbitmq {
  include ::profile::munin::plugins::rabbitmq

  $rabbitmq_user = lookup('rabbitmq::monitoring::user')
  $rabbitmq_password = lookup('rabbitmq::monitoring::password')
  # FIXME: improve this
  $rabbitmq_consumer = 'swhconsumer'
  $rabbitmq_consumer_pass = lookup('swh::deploy::worker::task_broker::password')

  $rabbitmq_vhost = '/'
  $rabbitmq_enable_guest = lookup('rabbitmq::enable::guest')

  class { 'rabbitmq':
    delete_guest_user => ! $rabbitmq_enable_guest,
    service_manage    => true,
    port              => 5672,
    admin_enable      => true,
    node_ip_address   => '0.0.0.0',
  }
  -> rabbitmq_user { $rabbitmq_user:
    admin    => true,
    password => $rabbitmq_password,
    provider => 'rabbitmqctl',
  }
  -> rabbitmq_user { $rabbitmq_consumer:
    admin    => true,
    password => $rabbitmq_consumer_pass,
    provider => 'rabbitmqctl',
  }
  -> rabbitmq_vhost { $rabbitmq_vhost:
    provider => 'rabbitmqctl',
  }

  rabbitmq_user_permissions { "${rabbitmq_user}@${rabbitmq_vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    provider             => 'rabbitmqctl',
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"rabbitmq-server on ${::fqdn}":
    service_name  => 'rabbitmq server',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'rabbitmq_server',
    vars          => {
      rabbitmq_port     => 15672,
      rabbitmq_vhost    => '/',
      rabbitmq_node     => $::hostname,
      rabbitmq_user     => $rabbitmq_user,
      rabbitmq_password => $rabbitmq_password,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
