class role::swh_base {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::puppet::agent

  include profile::swh
}
