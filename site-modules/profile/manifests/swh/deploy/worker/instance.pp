# Instance of a worker
define profile::swh::deploy::worker::instance (
  $ensure = present,
  $max_tasks_per_child = 5,
  $instance_name = $title,
  $limit_no_file = undef,
  $private_tmp = undef)
{
  include ::profile::swh::deploy::worker::base

  $service_basename = "swh-worker@${instance_name}"
  $service_name = "${service_basename}.service"
  $concurrency = lookup("swh::deploy::worker::${instance_name}::concurrency")
  $loglevel = lookup("swh::deploy::worker::${instance_name}::loglevel")
  $config_file = lookup("swh::deploy::worker::${instance_name}::config_file")
  $config = lookup("swh::deploy::worker::${instance_name}::config", Hash, 'deep')

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

      file {$config_file:
        ensure  => 'present',
        owner   => 'swhworker',
        group   => 'swhworker',
        mode    => '0644',
        content => inline_template("<%= @config.to_yaml %>\n"),
      }

      if $ensure == 'running' {
        $service_ensure = 'running'
      } else {
        $service_ensure = undef
      }

      service {$service_basename:
        ensure  => $service_ensure,
        enable  => true,
        require => [
          File[$config_file],
        ]
      }
    }
    default: {
      ::systemd::dropin_file {"${service_basename}/parameters.conf":
        ensure   => absent,
        unit     => $service_name,
        filename => 'parameters.conf',
      }
    }
  }
}
