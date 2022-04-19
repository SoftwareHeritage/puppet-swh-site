class role::swh_worker_elastic inherits role::swh_base {
  include profile::docker
  include profile::zfs::docker
}
