class role::swh_worker_inria_miracle inherits role::swh_worker_inria {
  # Add backups for /home
  include profile::dar::client

  include profile::swh::deploy::storage
}
