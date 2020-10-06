# Network configuration for Software Heritage servers.

# This class is enabled when the `networks` hiera variable returns a value that
# is not empty, and when the networks::manage_interfaces variable is set to
# true.

class profile::network {
  $interfaces = lookup('networks', {default_value => {}})
  $manage_interfaces = lookup('networks::manage_interfaces', {default_value => false})

  if $manage_interfaces and !empty($interfaces) {
    debnet::iface::loopback { 'lo':  }

    # The `networks` hiera variable is a dict mapping interface names to a
    # settings dict. Entries of the settings dict with undefined values are not
    # output in the interface configuration.
    # The settings dict has the following keys:
    # - type (defaults to 'static'): the type of the interface as used by
    #     ifupdown. A special type, 'private', generates a static configuration
    #     with a separate routing table for the networks defined in the
    #     `networks::private_routes` hiera variable (e.g. the OpenVPN and azure
    #     machines).
    # - order (int, defaults to 0): allows to control what order the interface blocks
    #     are in the /etc/network/interfaces file
    # - address (ip address): ip address to set on the
    #     interface
    # - netmask (int or netmask): netmask for the network (e.g. 26 or 255.255.255.192)
    # - gateway (ip address): address of the gateway to use for the network
    # - mtu (int): MTU to set for the interface
    # - extras (dict): extra configuration entries to pass to ifupdown directly
    # - ups (list[str]): Instructions to run after the interface is brought up
    # - downs (list[str]): instructions to run when the interface is torn down

    $private_routes = lookup('networks::private_routes', Hash, 'deep')

    each($interfaces) |$interface, $data| {

      $interface_type = pick($data['type'], 'static')

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
        $method = 'static'
        $gateway = undef
      } else {
        $method = $interface_type
        $gateway = $data['gateway']
        $_ups = []
        $_downs = []
      }

      # These offsets are set by trepasi-debnet
      $order_offsets = {
        manual   => 50,
        static   => 40,
        dhcp     => 30,
        loopback => 20,
        wvdial   => 60,
      }

      $order = (
        25                                 # Base order to be inserted after the loopback interface which is order = 20
        - $order_offsets[$method]          # counteract the built-in offsets
        + pick_default($data['order'], 0)  # get the order set in the interface stanza
      )

      debnet::iface { $interface:
        method  => $method,
        order   => $order,
        address => $data['address'],
        netmask => $data['netmask'],
        mtu     => $data['mtu'],
        gateway => $gateway,
        ups     => pick_default($data['ups'], $_ups, []),
        downs   => pick_default($data['downs'], $_downs, []),
        aux_ops => pick_default($data['extras'], {}),
      }
    }
  }
}
