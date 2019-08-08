class profile::rabbitmq {
  include ::profile::munin::plugins::rabbitmq

  $rabbitmq_vhost = '/'
  $rabbitmq_enable_guest = lookup('rabbitmq::enable::guest')

  $users = lookup('rabbitmq::server::users')

  class { 'rabbitmq':
    service_manage    => true,
    port              => 5672,
    admin_enable      => true,
    node_ip_address   => '0.0.0.0',
    config_variables  => {
      vm_memory_high_watermark => 0.6,
    },
    heartbeat         => 0,
    delete_guest_user => ! $rabbitmq_enable_guest,
  }
  -> rabbitmq_vhost { $rabbitmq_vhost:
    provider => 'rabbitmqctl',
  }

  each ( $users ) | $user | {
    $username = $user['name']
    rabbitmq_user { $username:
      admin    => $user['is_admin'],
      password => $user['password'],
      provider => 'rabbitmqctl',
    }
    -> rabbitmq_user_permissions { "${username}@${rabbitmq_vhost}":
      configure_permission => '.*',
      read_permission      => '.*',
      write_permission     => '.*',
      provider             => 'rabbitmqctl',
    }
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
