# Web ui profile with reverse proxy and swh-search backend
class role::swh_rp_webapp_with_swh_search inherits role::swh_rp_webapp {
  include profile::swh::deploy::search
}
