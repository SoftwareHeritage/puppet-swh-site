# - Webapp api without reverse proxy
# - storage
# - search
class role::swh_webapp inherits role::swh_server {
  include profile::memcached
  include profile::swh::deploy::storage
  include profile::swh::deploy::search
  include profile::swh::deploy::webapp
  include profile::filebeat
}
