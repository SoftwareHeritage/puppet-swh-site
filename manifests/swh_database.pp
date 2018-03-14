class role::swh_database inherits role::swh_server {
  include profile::puppet::agent

  include profile::prometheus::node
  include profile::prometheus::sql

  include profile::munin::plugins::postgresql
  include profile::postgresql
}
