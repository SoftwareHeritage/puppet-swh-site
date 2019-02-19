# Instance of a worker
define profile::swh::deploy::worker::instance (
  $ensure = present,
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

      if $ensure == 'running' {
        service {$service_basename:
          ensure  => $ensure,
        }
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
