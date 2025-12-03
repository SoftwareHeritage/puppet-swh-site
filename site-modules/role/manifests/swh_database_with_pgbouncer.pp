class role::swh_database_with_pgbouncer inherits role::swh_database {
  include profile::pgbouncer
}
