class role::swh_worker inherits role::swh_base {
  include profile::network
  include profile::swh::deploy::storage
}
