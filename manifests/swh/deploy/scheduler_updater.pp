# Deployment of swh-scheduler-updater related utilities

class profile::swh::deploy::scheduler_updater {
  # Package and backend configuration
  $scheduler_updater_packages = ['python3-swh.scheduler.updater']

  package {$scheduler_updater_packages:
    ensure => latest,
  }

  $backend_conf_dir = lookup('swh::deploy::scheduler::updater::backend::conf_dir')
  $backend_conf_file = lookup('swh::deploy::scheduler::updater::backend::conf_file')
  $backend_user = lookup('swh::deploy::scheduler::updater::backend::user')
  $backend_group = lookup('swh::deploy::scheduler::updater::backend::group')
  $backend_config = lookup('swh::deploy::scheduler::updater::backend::config')

  # file {$backend_conf_dir:
  #   ensure => directory,
  #   owner  => 'root',
  #   group  => $backend_group,
  #   mode   => '0755',
  # }

  file {$backend_conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $backend_group,
    mode    => '0640',
    content => inline_template("<%= @backend_config.to_yaml %>\n"),
  }

}
