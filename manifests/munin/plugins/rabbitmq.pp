class profile::munin::plugins::rabbitmq {
  munin::plugin {

    'rabbitmq_connections':
      ensure => present,
      source => 'puppet:///modules/profile/munin/rabbitmq/rabbitmq_connections',
      config => ['user root'];
    'rabbitmq_consumers':
      ensure => present,
      source => 'puppet:///modules/profile/munin/rabbitmq/rabbitmq_consumers',
      config => ['user root'];
    'rabbitmq_messages':
      ensure => present,
      source => 'puppet:///modules/profile/munin/rabbitmq/rabbitmq_messages',
      config => ['user root'];
    'rabbitmq_messages_unacknowledged':
      ensure => present,
      source => 'puppet:///modules/profile/munin/rabbitmq/rabbitmq_messages_unacknowledged',
      config => ['user root'];
    'rabbitmq_messages_uncommitted':
      ensure => present,
      source => 'puppet:///modules/profile/munin/rabbitmq/rabbitmq_messages_uncommitted',
      config => ['user root'];
    'rabbitmq_queue_memory':
      ensure => present,
      source => 'puppet:///modules/profile/munin/rabbitmq/rabbitmq_queue_memory',
      config => ['user root'];
  }
}
