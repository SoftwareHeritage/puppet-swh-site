# Deployment of the swh.storage.listener

class profile::swh::deploy::storage_listener {
  $conf_directory = lookup('swh::deploy::storage_listener::conf_directory')

  $service_name = 'swh-storage-listener'
  $unit_name = "${service_name}.service"

  package {'python3-swh.storage.listener':
    ensure => absent,
  }

  file {$conf_directory:
    ensure => absent,
    force  => true,
  }

  ::systemd::unit_file {$unit_name:
    ensure  => absent,
  }

  service {$service_name:
    ensure  => stopped,
    enable  => false,
  }
}
