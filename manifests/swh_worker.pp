class role::swh_worker inherits role::swh_base {
  include profile::puppet::agent
  include profile::swh::deploy::storage
  include profile::swh::deploy::worker
  include profile::mountpoints
}
