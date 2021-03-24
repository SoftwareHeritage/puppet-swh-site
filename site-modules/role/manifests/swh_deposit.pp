# Deposit api without reverse proxy
class role::swh_deposit inherits role::swh_server {
  include profile::memcached
  # Web UI
  include profile::swh::deploy::deposit
  # Apache logs
  include profile::filebeat
}
