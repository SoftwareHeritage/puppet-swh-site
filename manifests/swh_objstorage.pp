class role::swh_objstorage inherits role::swh_server {
  include profile::puppet::agent
  include profile::swh::deploy::objstorage
}
