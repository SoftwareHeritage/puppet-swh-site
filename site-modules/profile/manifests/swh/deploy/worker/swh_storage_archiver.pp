# Deployment for swh-storage-archiver
class profile::swh::deploy::worker::swh_storage_archiver {
  include ::profile::swh::deploy::archiver

  $concurrency = lookup('swh::deploy::worker::swh_storage_archiver::concurrency')
  $max_tasks_per_child = lookup('swh::deploy::worker::swh_storage_archiver::max_tasks_per_child')
  $loglevel = lookup('swh::deploy::worker::swh_storage_archiver::loglevel')

  $config_file = lookup('swh::deploy::worker::swh_storage_archiver::conf_file')
  $config = lookup('swh::deploy::worker::swh_storage_archiver::config')

  ::profile::swh::deploy::worker::instance {'swh_storage_archiver':
    ensure              => present,
    concurrency         => $concurrency,
    loglevel            => $loglevel,
    max_tasks_per_child => $max_tasks_per_child,
    require             => [
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
