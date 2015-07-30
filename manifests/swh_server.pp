class role::swh_server {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
}
