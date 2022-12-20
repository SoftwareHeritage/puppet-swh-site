# SWH provenance backend server
class role::swh_provenance inherits role::swh_server {

  include profile::rabbitmq

  include profile::postgresql
  include profile::postgresql::client
  include profile::prometheus::sql
}
