# Netbox template
class role::swh_netbox inherits role::swh_server {
  include profile::postgresql

  include profile::netbox
  include profile::netbox::reverse_proxy
}
