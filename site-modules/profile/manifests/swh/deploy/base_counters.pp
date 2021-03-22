# Base class for counters related manifests
class profile::swh::deploy::base_counters {
  $config_directory = lookup('swh::deploy::base_counters::config_directory')
  $user = lookup('swh::deploy::base_counters::user')
  $group = lookup('swh::deploy::base_counters::group')

  file {$config_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  $packages = ['python3-swh.counters']

  package {$packages:
    ensure => 'present',
  }

}
