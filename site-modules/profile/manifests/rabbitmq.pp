class profile::rabbitmq {

  $rabbitmq_vhost = '/'
  $rabbitmq_user = lookup('rabbitmq::monitoring::user')
  $rabbitmq_password = lookup('rabbitmq::monitoring::password')

  $users = lookup('rabbitmq::server::users')

  class { 'rabbitmq':
    service_manage    => true,
    port              => 5672,
    admin_enable      => true,
    node_ip_address   => '0.0.0.0',
    interface         => '0.0.0.0',
    config_variables  => {
      vm_memory_high_watermark => 0.6,
    },
    heartbeat         => 0,
  }
  -> rabbitmq_vhost { $rabbitmq_vhost:
    provider => 'rabbitmqctl',
  }

  each ( $users ) | $user | {
    $username = $user['name']
    rabbitmq_user { $username:
      admin    => $user['is_admin'],
      password => $user['password'],
      tags     => $user['tags'],
      provider => 'rabbitmqctl',
    }
    -> rabbitmq_user_permissions { "${username}@${rabbitmq_vhost}":
      configure_permission => '.*',
      read_permission      => '.*',
      write_permission     => '.*',
      provider             => 'rabbitmqctl',
    }
  }

  $prometheus_listen_network = lookup('prometheus::rabbitmq::listen_network', Optional[String], 'first', undef)
  $prometheus_listen_address = lookup('prometheus::rabbitmq::listen_address', Optional[String], 'first', undef)
  $prometheus_actual_listen_address = pick($prometheus_listen_address, ip_for_network($prometheus_listen_network))
  $prometheus_listen_port = lookup('prometheus::rabbitmq::listen_port')
  $prometheus_target = "${prometheus_actual_listen_address}:${prometheus_listen_port}"

  $prometheus_include_vhost = lookup('prometheus::rabbitmq::include_vhost')
  $prometheus_skip_vhost = lookup('prometheus::rabbitmq::skip_vhost')
  $prometheus_include_queues = lookup('prometheus::rabbitmq::include_queues')
  $prometheus_skip_queues = lookup('prometheus::rabbitmq::skip_queues')

  $prometheus_rabbit_capabilities = lookup('prometheus::rabbitmq::rabbit_capabilities', Array[String]).join(',')
  $prometheus_rabbit_exporters = lookup('prometheus::rabbitmq::rabbit_exporters', Array[String]).join(',')
  $prometheus_rabbit_timeout = lookup('prometheus::rabbitmq::rabbit_timeout', Integer)

  $prometheus_exclude_metrics = lookup('prometheus::rabbitmq::exclude_metrics', Array[String]).join(',')

  if versioncmp($::lsbmajdistrelease, '11') >= 0 {
    # Install the official plugin along rabbitmq
    rabbitmq_plugin {'rabbitmq_prometheus':
      ensure => present,
    }
  } else {
    # Buster and below, retrieve an extra exporter
    package {'prometheus-rabbitmq-exporter':
      ensure => 'present',
    } -> file {'/etc/default/prometheus-rabbitmq-exporter':
      ensure  => 'present',
      mode    => '0600', # Contains passwords
      owner   => 'root',
      group   => 'root',
      content => template('profile/rabbitmq/prometheus-rabbitmq-exporter.default.erb'),
    } ~> service {'prometheus-rabbitmq-exporter':
      ensure => 'running',
      enable => true,
    }
  }

  profile::prometheus::export_scrape_config {'rabbitmq':
      target => $prometheus_target,
  }

  # monitoring user for the icinga check
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  @@::icinga2::object::service {"rabbitmq-server on ${::fqdn}":
    service_name  => 'rabbitmq server',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'rabbitmq_server',
    vars          => {
      rabbitmq_port     => 15672,
      rabbitmq_vhost    => $rabbitmq_vhost,
      rabbitmq_node     => $::hostname,
      rabbitmq_user     => $rabbitmq_user,
      rabbitmq_password => $rabbitmq_password,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
