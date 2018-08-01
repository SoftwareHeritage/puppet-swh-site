class role::swh_kibana_instance inherits role::swh_base {
  include profile::puppet::agent
  include profile::kibana
}
