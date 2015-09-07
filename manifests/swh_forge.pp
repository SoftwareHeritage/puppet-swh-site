class role::swh_forge {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::dar::client

  include profile::phabricator
}
