# Declare the /etc/hosts entries
class profile::static_hostnames {

  $static_hostnames = lookup('static_hostnames', {default_value => {}})

  each($static_hostnames) |$ip, $properties| {
    host {$properties['host'] :
      ensure       => present,
      ip           => $ip,
      host_aliases => $properties['aliases']
    }
  }
}
