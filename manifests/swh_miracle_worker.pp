class role::swh_miracle_worker inherits role::swh_worker {
  # Add backups for /home
  include profile::dar::client

  include profile::swh::deploy::storage
}
