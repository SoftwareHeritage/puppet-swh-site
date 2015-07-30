class role::swh_forge {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
}
