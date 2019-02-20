# Deployment for archiver (content)
class profile::swh::deploy::worker::archiver {
  include ::profile::swh::deploy::archiver

  $max_tasks_per_child = lookup('swh::deploy::worker::archiver::max_tasks_per_child')

  ::profile::swh::deploy::worker::instance {'archiver':
    ensure              => present,
    max_tasks_per_child => $max_tasks_per_child,
    require             => [
      Package[$packages],
    ],
  }
}
