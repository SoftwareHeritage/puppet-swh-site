class role::swh_worker {
  include profile::base
  include profile::ssh::server
  include profile::network
  include profile::munin::node
  include profile::puppet::agent

  include profile::worker::deploy_key
}
