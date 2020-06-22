# Instance of a worker
define profile::swh::deploy::worker::instance (
  $ensure = present,
  $instance_name = $title,
  $sentry_name = $title,
  $limit_no_file = undef,
  $private_tmp = undef,
  $merge_policy = 'deep',
)
{
  include ::profile::swh::deploy::worker::base

  $service_basename = "swh-worker@${instance_name}"
  $service_name = "${service_basename}.service"
  $concurrency = lookup("swh::deploy::worker::${instance_name}::concurrency")
  $max_tasks_per_child = lookup("swh::deploy::worker::${instance_name}::max_tasks_per_child", Integer, first, 5)
  $loglevel = lookup("swh::deploy::worker::${instance_name}::loglevel")
  $config_file = lookup("swh::deploy::worker::${instance_name}::config_file")
  $config = lookup("swh::deploy::worker::${instance_name}::config", Hash, $merge_policy)

  $sentry_dsn = lookup("swh::deploy::${sentry_name}::sentry_dsn", Optional[String], 'first', undef)
  $sentry_environment = lookup("swh::deploy::${sentry_name}::sentry_environment", Optional[String], 'first', undef)
  $sentry_swh_package = lookup("swh::deploy::${sentry_name}::sentry_swh_package", Optional[String], 'first', undef)

  $celery_hostname = $::profile::swh::deploy::worker::base::celery_hostname

  case $ensure {
    'present', 'running': {
      # Uses variables
      # - $concurrency
      # - $loglevel
      # - $max_tasks_per_child
      # - $celery_hostname
      # - $sentry_{dsn,environment,swh_package}
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

      profile::cron::d {"swh-worker-${instance_name}-autorestart":
        command => "chronic /usr/local/sbin/swh-worker-ping-restart ${instance_name}@${celery_hostname} ${service_name}",
        target  => 'swh-worker',
        minute  => 'fqdn_rand/15',
        require => File['/usr/local/sbin/swh-worker-ping-restart'],
      }
    }
    default: {
      ::systemd::dropin_file {"${service_basename}/parameters.conf":
        ensure   => absent,
        unit     => $service_name,
        filename => 'parameters.conf',
      }


      file {$config_file:
        ensure  => absent,
      }
    }
  }
}
