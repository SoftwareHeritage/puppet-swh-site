# Instance of a worker
define profile::swh::deploy::search::journal_client_instance (
  $ensure = present,
  $instance_name = $title,
)
{
  include profile::swh::deploy::base_search

  $service_name = "swh-search-journal-client@${instance_name}"

  $config_path = lookup("swh::deploy::search::journal_client::${instance_name}::config_file")
  $config = lookup("swh::deploy::search::journal_client::${instance_name}::config", Hash, 'deep')

  $user = lookup('swh::deploy::base_search::user')
  $group = lookup('swh::deploy::base_search::group')

  case $ensure {
    'present', 'running': {

      file {$config_path:
        ensure  => 'present',
        owner   => $user,
        group   => $group,
        mode    => '0644',
        content => inline_template("<%= @config.to_yaml %>\n"),
        notify  => Service[$service_name],
      }

      if $ensure == 'running' {
        $service_ensure = 'running'
      } else {
        $service_ensure = undef
      }

      service {$service_name:
        ensure  => $service_ensure,
        enable  => true,
        require => [
          File[$config_path],
        ]
      }
    }
    default: {
      # clean up
      service {$service_name:
        ensure => absent,
      }
      -> file {$config_path:
        ensure  => absent,
      }
    }
  }
}
