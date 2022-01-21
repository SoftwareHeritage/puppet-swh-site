# Netbox template
class role::swh_netbox inherits role::swh_server {
  include profile::netbox
  include profile::netbox::reverse_proxy
  # redirect inventory.i.s.o -> inventory.i.a.s.n
  include profile::apache::rewrite_domains
}
