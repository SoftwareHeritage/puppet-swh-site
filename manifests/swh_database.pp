class role::swh_database {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::dar::client
  include profile::munin::plugins::postgresql
}
