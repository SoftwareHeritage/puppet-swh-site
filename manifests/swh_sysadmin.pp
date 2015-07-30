class role::swh_sysadmin {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::munin::master
}
