class role::swh_api {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
}
