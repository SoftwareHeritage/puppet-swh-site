# Deployment of the swh.indexer.journal_client
define profile::swh::deploy::indexer_journal_client (
  $ensure = present,
  $instance_name = $title,
  $sentry_name = $title,
)
{
  include ::profile::swh::deploy::base_indexer
  include ::profile::swh::deploy::journal

  $config_file = lookup("swh::deploy::indexer_journal_client::${instance_name}::config_file")
  $config_directory = $::profile::swh::deploy::base_indexer::config_directory
  $config_path = "${config_directory}/${config_file}"

  $service_basename = $::profile::swh::deploy::base_indexer::service_basename
  $service_name = "${service_basename}@${instance_name}.service"
  $parameters_conf_path = "${service_name}/parameters.conf"

  case $ensure {
    'present', 'running': {
      $config = lookup("swh::deploy::indexer_journal_client::${instance_name}::config")
      $loglevel = lookup("swh::deploy::indexer_journal_client::${instance_name}::loglevel")

      $sentry_dsn = lookup("swh::deploy::indexer::sentry_dsn", Optional[String], "first", undef)
      $sentry_environment = lookup("swh::deploy::indexer::sentry_environment", Optional[String], "first", undef)
      $sentry_swh_package = lookup("swh::deploy::indexer::sentry_swh_package", Optional[String], "first", undef)

      file {$config_path:
        ensure  => present,
        owner   => "root",
        group   => $::profile::swh::deploy::base_indexer::group,
        mode    => "0640",
        content => inline_template("<%= @config.to_yaml %>\n"),
        notify  => Service[$service_name],
        require => File[$config_directory],
      }

      # Template uses variables
      #  - $config_path
      #  - $sentry_dsn
      #  - $sentry_environment
      #  - $sentry_swh_package
      #  - $loglevel
      ::systemd::dropin_file {$parameters_conf_path:
        ensure   => present,
        unit     => $service_name,
        filename => 'parameters.conf',
        content  => template('profile/swh/deploy/journal/parameters.conf.erb'),
      }

      service {$service_name:
        ensure => running,
        enable => true,
        require => [
          File[$config_path],
        ],
      }
    }

    # Otherwise, clean up everything
    default: {
      ::systemd::dropin_file {$parameters_conf_path:
        ensure   => absent,
        unit     => $service_name,
        filename => 'parameters.conf',
      }

      service {$service_basename:
        ensure => stopped,
      }

      file {$config_path:
        ensure => absent,
      }
    }
  }
}
