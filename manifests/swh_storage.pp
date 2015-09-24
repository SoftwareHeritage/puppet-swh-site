class role::swh_storage inherits role::swh_server {
  include profile::swh::deploy::storage
}
