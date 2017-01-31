class role::swh_api inherits role::swh_server {
  include profile::network
  include profile::puppet::agent

  # Web UI
  include profile::redis
  include profile::swh::deploy::storage
  include profile::swh::deploy::webapp
}
