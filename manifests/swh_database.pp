class role::swh_database inherits role::swh_server {
  include profile::munin::plugins::postgresql
}
