class role::swh_api inherits role::swh_server {
  include profile::network
  include profile::puppet::agent

  # Web UI
  include profile::memcached
  include profile::swh::deploy::storage
  include profile::swh::deploy::indexer::storage
  include profile::swh::deploy::webapp
  include profile::swh::deploy::deposit
}
