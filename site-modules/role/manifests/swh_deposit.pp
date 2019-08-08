class role::swh_deposit inherits role::swh_server {
  include profile::puppet::agent
  include profile::network

  # Web UI
  include profile::swh::deploy::deposit

  # Apache logs
  include profile::filebeat
}
