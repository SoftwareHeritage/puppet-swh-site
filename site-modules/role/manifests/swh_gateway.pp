class role::swh_gateway inherits role::swh_base {
  include profile::network
  include profile::puppet::agent
}
