# Munin master class
class profile::munin::master {
  $master_hostname = lookup('munin::master::hostname')

  apache::vhost { $master_hostname:
    ensure => 'absent',
  }
}
