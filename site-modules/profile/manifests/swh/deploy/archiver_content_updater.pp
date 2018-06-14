# Deployment of the swh.storage.archiver.updater

class profile::swh::deploy::archiver_content_updater {
  include profile::swh::deploy::archiver

  $conf_file = lookup('swh::deploy::archiver_content_updater::conf_file')
  $user = lookup('swh::deploy::archiver_content_updater::user')
  $group = lookup('swh::deploy::archiver_content_updater::group')

  $content_updater_config = lookup('swh::deploy::archiver_content_updater::config')

  $service_name = 'swh-archiver-content-updater'
  $unit_name = "${service_name}.service"

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @content_updater_config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/swh/deploy/archiver/swh-content-updater.service.erb'),
  } ~> service {$service_name:
    ensure  => running,
    enable  => false,
    require => File[$conf_file],
  }
}
