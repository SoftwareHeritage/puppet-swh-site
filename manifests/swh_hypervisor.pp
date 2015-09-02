class role::swh_hypervisor {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::dar::client
}
