class role::swh_deposit inherits role::swh_server {
  # Web UI
  include profile::swh::deploy::deposit

  # Apache logs
  include profile::filebeat
}
