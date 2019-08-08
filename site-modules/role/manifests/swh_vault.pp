class role::swh_vault inherits role::swh_server {
  include profile::puppet::agent
  include profile::swh::deploy::vault
}
