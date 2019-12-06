class role::swh_vault_test inherits role::swh_server {
  include profile::puppet::agent

  include profile::swh::deploy::vault
  include profile::swh::deploy::worker

  include profile::postgresql

  include profile::swh::deploy::objstorage
}
