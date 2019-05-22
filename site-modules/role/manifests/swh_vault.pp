class role::swh_vault inherits role::swh_server {
  include profile::puppet::agent
  include profile::swh::deploy::vault

  include profile::swh::deploy::objstorage
}
