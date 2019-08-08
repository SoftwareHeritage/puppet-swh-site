class role::swh_base_database inherits role::swh_server {
  include profile::puppet::agent
  include profile::prometheus::sql
}
