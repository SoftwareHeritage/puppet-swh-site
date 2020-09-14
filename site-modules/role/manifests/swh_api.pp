class role::swh_api inherits role::swh_base_api {
  # Extra deposit and storage services
  include profile::swh::deploy::deposit
  include profile::swh::deploy::storage
}
