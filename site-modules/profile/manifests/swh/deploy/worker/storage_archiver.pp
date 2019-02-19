# Deployment for swh-storage-archiver
class profile::swh::deploy::worker::storage_archiver {
  include ::profile::swh::deploy::archiver

  $max_tasks_per_child = lookup('swh::deploy::worker::storage_archiver::max_tasks_per_child')

  ::profile::swh::deploy::worker::instance {'storage_archiver':
    ensure              => present,
    max_tasks_per_child => $max_tasks_per_child,
    require             => [
      Package[$packages],
    ],
  }
}
