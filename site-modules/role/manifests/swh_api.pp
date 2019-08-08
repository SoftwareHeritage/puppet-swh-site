class role::swh_api inherits role::swh_base_api {
  include profile::network

  # Extra deposit and storage services
  include profile::swh::deploy::deposit
}
