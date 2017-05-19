class profile::rabbitmq {
  include ::profile::munin::plugins::rabbitmq

  $rabbitmq_user = hiera('rabbitmq::monitoring::user')
  $rabbitmq_password = hiera('rabbitmq::monitoring::password')

  package {'rabbitmq-server':
    ensure => installed
  }

  service {'rabbitmq-server':
    ensure  => 'running',
    enable  => true,
    require => Package['rabbitmq-server'],
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
