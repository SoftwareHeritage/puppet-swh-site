class role::swh_worker inherits role::swh_base {
  include profile::swh::deploy::worker
  include profile::mountpoints
}
