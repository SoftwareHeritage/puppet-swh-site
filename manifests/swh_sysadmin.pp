class role::swh_sysadmin {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::munin::master
  include profile::puppet::master
  include profile::apache::simple_server
  include profile::bind_server
  include profile::munin::plugins::postgresql
}
