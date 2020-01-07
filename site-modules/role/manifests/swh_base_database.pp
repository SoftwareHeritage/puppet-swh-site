class role::swh_base_database inherits role::swh_server {
  include profile::prometheus::sql
}
