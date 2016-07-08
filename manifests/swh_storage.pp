class role::swh_storage inherits role::swh_server {
  include profile::puppet::agent
  include profile::swh::deploy::storage
  include profile::swh::deploy::storage_archiver
}
