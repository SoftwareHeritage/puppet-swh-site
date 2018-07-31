# Deployment of swh-scheduler-updater related utilities
class profile::swh::deploy::scheduler_updater_consumer {
  include ::profile::swh::deploy::scheduler_updater

  # only ghtorrent so far
  $consumer_conf_dir = lookup('swh::deploy::scheduler::updater::consumer::ghtorrent::conf_dir')
  $consumer_conf_file = lookup('swh::deploy::scheduler::updater::consumer::ghtorrent::conf_file')
  $consumer_user = lookup('swh::deploy::scheduler::updater::consumer::user')
  $consumer_group = lookup('swh::deploy::scheduler::updater::consumer::group')

  $packages = ['autossh']
  package {$packages:
    ensure => present,
  }

#  file {$consumer_conf_dir:
#    ensure => directory,
#    owner  => 'root',
#    group  => $consumer_group,
#    mode   => '0755',
#  }

  $consumer_config = lookup('swh::deploy::scheduler::updater::consumer::ghtorrent::config')
  file {$consumer_conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $consumer_group,
    mode    => '0640',
    content => inline_template("<%= @consumer_config.to_yaml %>\n"),
  }

  # service needed to forward port locally

  $local_port = lookup('swh::deploy::scheduler::updater::consumer::ghtorrent::port')
  $ghtorrent_private_key_raw = lookup('swh::deploy::scheduler::updater::consumer::ghtorrent::private_key')
  $ghtorrent_private_key = "/home/${consumer_user}/.ssh/id-rsa-swh-ghtorrent"

  # write private key to access the ghtorrent infra
  file {$ghtorrent_private_key:
    ensure  => present,
    owner   => $consumer_user,
    group   => $consumer_group,
    mode    => '0600',
    content => inline_template("<%= @ghtorrent_private_key_raw %>"),
  }

  $ghtorrent_service_name = 'ssh-ghtorrent'
  $ghtorrent_unit_name = "${ghtorrent_service_name}.service"
  # Service to open up the ghtorrent connection infra (no consumption)
  ::systemd::unit_file {$ghtorrent_unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/scheduler/${ghtorrent_unit_name}.erb"),
    require => Package[$packages],
  } ~> service {$ghtorrent_service_name:
    ensure  => stopped,
    enable  => true,
    require => File[$ghtorrent_private_key],
  }

  # actual service consuming from ghtorrent

  $ghtorrent_consumer_service = 'swh-scheduler-updater-consumer-ghtorrent'
  $ghtorrent_consumer_unit_name = "${ghtorrent_consumer_service}.service"
  # Service to consume from ghtorrent
  ::systemd::unit_file {$ghtorrent_consumer_unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/scheduler/${ghtorrent_consumer_unit_name}.erb"),
  } ~> service {$ghtorrent_consumer_service:
    ensure  => stopped,
    enable  => true,
    require => Service[$ghtorrent_service_name],
  }

}
