class role::swh_base {
  include profile::base
  include profile::ssh::server
  include profile::unbound
  include profile::resolv_conf
  include profile::munin::node

  include profile::swh
}
