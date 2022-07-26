# Base class for indexer related manifests
class profile::swh::deploy::base_indexer {
  $config_directory = lookup('swh::deploy::base_indexer::config_directory')
  $service_basename = "swh-indexer-journal-client"
  $unit_name = "${service_basename}@.service"

  $user = lookup("swh::deploy::indexer::user")
  $group = lookup("swh::deploy::indexer::group")
  $sentry_name = 'indexer'

  file {$config_directory:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0755',
  }

  $packages = ['python3-swh.indexer']
  package {$packages:
    ensure => 'present',
  }

  # Template uses variables
  #  - $user
  #  - $group
  #  - $config_directory
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/journal/${unit_name}.erb"),
  }
}
