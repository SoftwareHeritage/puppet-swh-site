# Network configuration for Software Heritage servers
class profile::network {
  debnet::iface::loopback { 'lo': }

  # The network description is expected to be a dict of key route_label
  # (values: private, default) and value a dict describing the interface.
  # The interface dict has the following possible keys:
  # - interface: interface's name
  # - address: ip address for the node
  # - netmask: netmask
  # - gateway: to use for the network
  # - ups: Post instruction when the interface is up
  # - downs: Post instructions to run when the interface is teared down

  $interfaces = lookup('networks')
  $private_routes = lookup('networks::private_routes', Hash, 'deep')
  each($interfaces) |$interface, $data| {

    $interface_type = pick($data['type'], 'default')

    if $interface_type == 'private' {
      file_line {'private route table':
        ensure => 'present',
        line   => '42 private',
        path   => '/etc/iproute2/rt_tables',
      }

      $filtered_routes = $private_routes.filter |$route_label, $route_data| { pick($route_data['enabled'], true) }

      $routes_up = $filtered_routes.map |$route_label, $route_data| {
        "ip route add ${route_data['network']} via ${route_data['gateway']}"
      }

      $routes_down = $filtered_routes.map |$route_label, $route_data| {
        "ip route del ${route_data['network']} via ${route_data['gateway']}"
      }.reverse

      $_ups = $routes_up + [
        "ip rule add from ${data['address']} table private",
        "ip route add 192.168.100.0/24 src ${data['address']} dev ${interface} table private",
        "ip route add default via ${data['gateway']} dev ${interface} table private",
        'ip route flush cache',
      ]

      $_downs = [
        "ip route del default via ${data['gateway']} dev ${interface} table private",
        "ip route del 192.168.100.0/24 src ${data['address']} dev ${interface} table private",
        "ip rule del from ${data['address']} table private",
      ] + $routes_down + [
        'ip route flush cache',
      ]

      $ups = pick_default($data['ups'], $_ups)
      $downs = pick_default($data['downs'], $_downs)
      $gateway = undef

    } else {
      $ups = pick_default($data['ups'], [])
      $downs = pick_default($data['downs'], [])
      $gateway = $data['gateway']
    }


    debnet::iface { $interface:
      method  => 'static',
      address => $data['address'],
      netmask => $data['netmask'],
      gateway => $gateway,
      ups     => $ups,
      downs   => $downs,
    }
  }
}
