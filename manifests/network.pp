# Network configuration for Software Heritage servers
#
# Supports one private and one public interface
class profile::network {
  debnet::iface::loopback { 'lo': }

  $interfaces = hiera('networks')
  each($interfaces) |$label, $data| {

    if $label == 'private' {
      file_line {'private route table':
        ensure => 'present',
        line   => '42 private',
        path   => '/etc/iproute2/rt_tables',
      }
      $ups = [
        "ip route add 192.168.101.0/24 via ${data['gateway']}",
        "ip rule add from ${data['address']} table private",
        "ip route add default via ${data['gateway']} dev ${data['interface']} table private",
        'ip route flush cache',
      ]
      $downs = [
        "ip route del default via ${data['gateway']} dev ${data['interface']} table private",
        "ip rule del from ${data['address']} table private",
        "ip route del 192.168.101.0/24 via ${data['gateway']}",
        'ip route flush cache',
      ]
      $gateway = undef
    } else {
      $ups = []
      $downs = []
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
