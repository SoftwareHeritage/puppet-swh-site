# Network configuration for Software Heritage servers
#
# Supports one private and one public interface
class profile::network {
  debnet::iface::loopback { 'lo': }

  # The network description is expected to be a dict of key route_label
  # (values: private, default) and value a dict describing the interface.
  # The interface dict has the following possible keys:
  # - interface: interface's name
  # - address: ip address for the node
  # - netmask: netmask
  # - gateway: to use for the network
  # - ups: Post instruction when the interface is up (should be set to [] when
  # none)
  # - downs: Post instructions to run when the interface is teared down (should
  # be set to [] when none)

  $interfaces = lookup('networks')
  each($interfaces) |$label, $data| {

    if $label == 'private' {
      file_line {'private route table':
        ensure => 'present',
        line   => '42 private',
        path   => '/etc/iproute2/rt_tables',
      }

      if $data['ups'] {
        $ups = $data['ups']
      } else {
        $ups = [
          "ip route add 192.168.101.0/24 via ${data['gateway']}",
          "ip route add 192.168.200.0/21 via ${data['gateway']}",
          "ip rule add from ${data['address']} table private",
          "ip route add 192.168.100.0/24 src ${data['address']} dev ${data['interface']} table private",
          "ip route add default via ${data['gateway']} dev ${data['interface']} table private",
          'ip route flush cache',
        ]
      }

      if $data['downs'] {
        $downs =  $data['downs']
      } else {
        $downs = [
          "ip route del default via ${data['gateway']} dev ${data['interface']} table private",
          "ip route del 192.168.100.0/24 src ${data['address']} dev ${data['interface']} table private",
          "ip rule del from ${data['address']} table private",
          "ip route del 192.168.200.0/24 via ${data['gateway']}",
          "ip route del 192.168.101.0/24 via ${data['gateway']}",
          'ip route flush cache',
        ]
      }

      $gateway = undef
    } else {
      if $data['ups'] {
        $ups = $data['ups']
      } else {
        $ups = []
      }

      if $data['downs'] {
        $downs = $data['downs']
      } else {
        $downs = []
      }
      $gateway = $data['gateway']
    }


    debnet::iface { $data['interface']:
      method  => 'static',
      address => $data['address'],
      netmask => $data['netmask'],
      gateway => $gateway,
      ups     => $ups,
      downs   => $downs,
    }
  }
}
