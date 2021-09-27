# SWH provenance backend server
class role::swh_provenance inherits role::swh_server {

  include profile::rabbitmq

  include profile::postgresql
  include profile::postgresql::server
  include profile::pgbouncer
  include profile::postgresql::client
  include profile::prometheus::sql

  include profile::docker
}


