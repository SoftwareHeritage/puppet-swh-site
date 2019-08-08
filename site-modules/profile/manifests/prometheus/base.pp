# Base configuration for all prometheus exporters
class profile::prometheus::base {
  include profile::prometheus::apt_config

  file {'/etc/prometheus':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
}
