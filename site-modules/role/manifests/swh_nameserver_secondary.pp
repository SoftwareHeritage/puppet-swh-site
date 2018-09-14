class role::swh_nameserver_secondary inherits role::swh_base {
  include profile::bind_server::secondary
  include profile::puppet::agent
}
