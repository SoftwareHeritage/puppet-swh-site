class role::swh_vault inherits role::swh_server {
  include profile::swh::deploy::vault
}
