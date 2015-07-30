class role::swh_storage {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
}
