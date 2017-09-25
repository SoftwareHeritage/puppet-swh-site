class role::swh_remote_objstorage inherits role::swh_base {
  include profile::puppet::agent
  include profile::swh::deploy::objstorage
}
