# Base class for Software Heritage-specific configuration

class profile::swh {
  $swh_base_directory = lookup('swh::base_directory')
  $swh_conf_directory = lookup('swh::conf_directory')
  $swh_global_conf_file = lookup('swh::global_conf::file')
  $swh_global_conf_contents = lookup('swh::global_conf::contents')
  $swh_log_directory = lookup('swh::log_directory')

  $swh_logrotate_conf = '/etc/logrotate.d/softwareheritage'

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

  file {$swh_global_conf_file:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $swh_global_conf_contents,
  }

  file {$swh_logrotate_conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/logrotate.conf.erb'),
  }

  include profile::swh::deploy
  include profile::swh::apt_config
}
