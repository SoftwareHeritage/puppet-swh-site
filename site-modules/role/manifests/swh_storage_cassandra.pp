class role::swh_storage_cassandra inherits role::swh_server {
  include profile::swh::deploy::storage
}
