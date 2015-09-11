# Base class for Software Heritage-specific configuration

class profile::swh {
  $swh_base_directory = hiera('swh::base_directory')
  $swh_conf_directory = hiera('swh::conf_directory')

  file {[
    $swh_base_directory,
    $swh_conf_directory,
  ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  include profile::swh::deploy
}
