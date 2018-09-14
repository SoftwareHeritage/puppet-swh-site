class role::swh_nameserver_secondary inherits role::swh_base {
  include profile::bind_server_secondary
  include profile::puppet::agent
}
