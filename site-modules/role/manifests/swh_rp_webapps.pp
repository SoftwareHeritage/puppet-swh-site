class role::swh_rp_webapps inherits role::swh_rp_webapp {
  # Extra deposit and storage services
  include profile::swh::deploy::deposit
  include profile::swh::deploy::storage
  include profile::swh::deploy::search
}
