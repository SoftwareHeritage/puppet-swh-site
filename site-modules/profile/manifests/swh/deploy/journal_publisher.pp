# Deployment of the swh.journal.publisher

class profile::swh::deploy::journal_publisher {

  $conf_file = lookup('swh::deploy::journal_publisher::conf_file')

  $service_name = 'swh-journal-publisher'
  $unit_name = "${service_name}.service"

  file {$conf_file:
    ensure  => absent,
  }

  ::systemd::unit_file {$unit_name:
    ensure  => absent,
  }

  service {$service_name:
    ensure => stopped,
    enable => false,
  }
}
