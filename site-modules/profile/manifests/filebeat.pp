# Filebeat apache log shipper profile

class profile::filebeat {
  include ::profile::elastic::apt_config

  $version = lookup('elastic::elk_version')

  package { 'filebeat':
    ensure => $version,
  }

  apt::pin { 'filebeat':
    packages => 'filebeat',
    version  => $version,
    priority => 1001,
  }

  service { 'filebeat':
    ensure => running,
    enable => true,
  }
}
