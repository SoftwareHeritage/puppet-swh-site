class profile::rabbitmq {
  include ::profile::munin::plugins::rabbitmq
  include ::profile::icinga2::plugins::rabbitmq

  package {'rabbitmq-server':
    ensure => installed
  }

  service {'rabbitmq-server':
    ensure  => 'running',
    enable  => true,
    require => Package['rabbitmq-server'],
  }
}
