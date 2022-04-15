class role::swh_database_staging inherits role::swh_database {
  include profile::postgresql::server
  include profile::pgbouncer
  include profile::postgresql::client
}
