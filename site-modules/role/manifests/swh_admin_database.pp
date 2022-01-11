class role::swh_admin_database inherits role::swh_base_database {
  include profile::postgresql
  include profile::postgresql::server
  include profile::prometheus::sql
}
