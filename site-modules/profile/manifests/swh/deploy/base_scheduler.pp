# Base class for scheduler related manifests
class profile::swh::deploy::base_scheduler {
  $config_directory = lookup('swh::deploy::scheduler::conf_dir')
  $user = lookup('swh::deploy::scheduler::user')
  $group = lookup('swh::deploy::scheduler::group')
  $config = lookup('swh::deploy::scheduler::config')

  $packages = lookup('swh::deploy::scheduler::packages')

  file {$config_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  package {$packages:
    ensure => installed,
  }

}
