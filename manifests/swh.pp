# Base class for Software Heritage-specific configuration

class profile::swh {
  $swh_base_directory = hiera('swh::base_directory')
  $swh_conf_directory = hiera('swh::conf_directory')
  $swh_log_directory = hiera('swh::log_directory')

  $swh_logrotate_conf = '/etc/logrotate/softwareheritage'

  $swh_mirror_location = hiera('swh::debian_mirror::location')

  file {[
    $swh_base_directory,
    $swh_conf_directory,
    $swh_log_directory,
  ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {$swh_logrotate_conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/logrotate.conf.erb'),
  }

  include ::apt
  ::apt::source {'softwareheritage':
    comment        => 'Software Heritage specific package repository',
    location       => $swh_mirror_location,
    release        => $::lsbdistcodename,
    repos          => 'main',
    allow_unsigned => true,
  }

  include profile::swh::deploy
}
