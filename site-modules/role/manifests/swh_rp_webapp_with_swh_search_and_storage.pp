# Web ui profile with reverse proxy, swh-search and swh-storage backend
class role::swh_rp_webapp_with_swh_search_and_storage inherits role::swh_rp_webapp {
  include profile::swh::deploy::search
  include profile::swh::deploy::storage
}
