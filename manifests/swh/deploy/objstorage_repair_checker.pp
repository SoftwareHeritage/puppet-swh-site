# Deployment of the swh.objstorage.checker.RepairContentChecker

class profile::swh::deploy::objstorage_repair_checker {
  $conf_directory = lookup('swh::deploy::objstorage_repair_checker::conf_directory')
  $conf_file = lookup('swh::deploy::objstorage_repair_checker::conf_file')
  $user = lookup('swh::deploy::objstorage_repair_checker::user')
  $group = lookup('swh::deploy::objstorage_repair_checker::group')

  $repair_checker_config = lookup('swh::deploy::objstorage_repair_checker::config')

  $swh_packages = ['python3-swh.objstorage.checker']

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
  }

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @repair_checker_config.to_yaml %>\n"),
  }

  ::systemd::unit_file {'objstorage_repair_checker.service':
    ensure  => present,
    content => template('profile/swh/deploy/storage/objstorage_repair_checker.service.erb'),
    require => [
      File[$conf_file],
      Package[$swh_packages],
    ]
  }

}
