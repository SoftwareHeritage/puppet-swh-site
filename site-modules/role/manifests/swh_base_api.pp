class role::swh_base_api inherits role::swh_server {
  # Web UI
  include profile::memcached
  include profile::swh::deploy::webapp

  # Apache logs
  include profile::filebeat
}
