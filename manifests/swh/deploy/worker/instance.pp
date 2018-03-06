# Instance of a worker
define profile::swh::deploy::worker::instance (
  $ensure = present,
  $task_broker = '',
  $task_modules = [],
  $task_queues = [],
  $task_soft_time_limit = 0,
  $concurrency = 10,
  $loglevel = 'info',
  $max_tasks_per_child = 5,
  $instance_name = $title,
  $limit_no_file = undef,
  $private_tmp = undef)
{
  include ::profile::swh::deploy::worker::base

  $service_basename = "swh-worker@${instance_name}"
  $service_name = "${service_basename}.service"
  $config_directory = '/etc/softwareheritage/worker'
  $instance_config = "${config_directory}/${instance_name}.ini"

  case $ensure {
    'present', 'running': {
      # Uses variables
      # - $concurrency
      # - $loglevel
      # - $max_tasks_per_child
      ::systemd::dropin_file {"${service_basename}/parameters.conf":
        ensure   => present,
        unit     => $service_name,
        filename => 'parameters.conf',
        content  => template('profile/swh/deploy/worker/parameters.conf.erb'),
      }

      # Uses variables
      # - $task_broker
      # - $task_modules
      # - $task_queues
      # - $task_soft_time_limit
      file {$instance_config:
        ensure  => present,
        owner   => 'swhworker',
        group   => 'swhdev',
        # contains a password for the broker
        mode    => '0640',
        content => template('profile/swh/deploy/worker/instance_config.ini.erb'),
      }
      if $ensure == 'running' {
        service {$service_basename:
          ensure  => $ensure,
          require => [
            File[$instance_config],
          ],
        }
      }
    }
    default: {
      file {$instance_config:
        ensure => absent,
      }
      ::systemd::dropin_file {"${service_basename}/parameters.conf":
        ensure   => absent,
        unit     => $service_name,
        filename => 'parameters.conf',
      }
    }
  }
}
