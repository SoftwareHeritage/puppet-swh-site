class role::swh_base_api inherits role::swh_server {
  include profile::puppet::agent

  # Web UI
  include profile::memcached
  include profile::swh::deploy::storage
  include profile::swh::deploy::webapp

  # Apache logs
  include profile::filebeat
}
