# Web ui profile with reverse proxy
class role::swh_rp_webapp inherits role::swh_webapp {
  include profile::swh::deploy::reverse_proxy
}
