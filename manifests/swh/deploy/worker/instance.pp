# Instance of a worker
define profile::swh::deploy::worker::instance (
  $ensure = present,
  $task_broker = '',
  $task_modules = [],
  $task_queues = [],
  $task_soft_time_limit = '',
  $concurrency = 10,
  $loglevel = 'info',
  $max_tasks_per_child = 5,
  $instance_name = $title)
{
  include ::profile::swh::deploy::worker::base
  include ::systemd

  $service_basename = "swh-worker@${instance_name}"
  $service_name = "${service_basename}.service"
  $systemd_dir = "/etc/systemd/system/${service_name}.d"
  $systemd_snippet = "${systemd_dir}/parameters.conf"
  $config_directory = '/etc/softwareheritage/worker'
  $instance_config = "${config_directory}/${instance_name}.ini"

  case $ensure {
    'present': {
      file {$systemd_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }

      # Uses variables
      # - $concurrency
      # - $loglevel
      # - $max_tasks_per_child
      file {$systemd_snippet:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/swh/deploy/worker/parameters.conf.erb'),
        notify  => [
          Exec['systemd-daemon-reload'],
          Service[$service_basename],
        ],
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

      service {$service_basename:
        ensure  => running,
        require => [
          File[$instance_config],
          File[$systemd_snippet],
        ],
      }

    }
    default: {
      file {[
        $systemd_dir,
        $instance_config,
      ]:
        ensure => absent,
      }

      service {$service_basename:
        ensure => stopped,
      }
    }
  }
}
