# Base class for search related manifests
class profile::swh::deploy::base_search {
  $config_directory = lookup('swh::deploy::base_search::config_directory')
  $user = lookup('swh::deploy::base_search::user')
  $group = lookup('swh::deploy::base_search::group')

  file {$config_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  $packages = ['python3-swh.search']

  package {$packages:
    ensure => 'present',
  }

}
