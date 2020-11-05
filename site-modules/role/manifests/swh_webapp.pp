# Webapp api without reverse proxy
class role::swh_webapp inherits role::swh_server {
  include profile::memcached
  include profile::swh::deploy::webapp
  include profile::filebeat
}
