# expansion of role::swh_api
# -network: incompatible with Azure infrastructure
# -deposit: not need for it

class role::swh_api_azure inherits role::swh_server {
  include profile::puppet::agent

  # Web UI
  include profile::memcached
  include profile::swh::deploy::storage
  include profile::swh::deploy::webapp
}
