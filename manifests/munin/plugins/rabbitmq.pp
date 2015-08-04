class profile::munin::plugins::rabbitmq {
  $messages_warn = hiera('munin::plugins::rabbitmq::messages_warn')
  $messages_crit = hiera('munin::plugins::rabbitmq::messages_crit')
  $queue_memory_warn = hiera('munin::plugins::rabbitmq::queue_memory_warn')
  $queue_memory_crit = hiera('munin::plugins::rabbitmq::queue_memory_crit')

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
      config => [
        'user root',
        "env.queue_warn ${messages_warn}",
        "env.queue_crit ${messages_crit}",
      ];
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
      config => [
        'user root',
        "env.queue_warn ${queue_memory_warn}",
        "env.queue_crit ${queue_memory_crit}",
      ];
  }
}
