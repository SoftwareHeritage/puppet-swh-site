# Install and configure logstash
class profile::logstash {
  include ::java
  include ::profile::elastic::apt_config

  $version = sprintf('1:%s-1', lookup('elastic::elk_version'))

  $elasticsearch_hosts = lookup('logstash::elasticsearch::hosts')
  $listen_address = ip_for_network(lookup('kibana::listen_network'))

  package { 'logstash':
    ensure  => $version,
    require => Class['java'],
  }

  apt::pin { 'logstash':
    packages => 'logstash',
    version  => $version,
    priority => 1001,
  }

  file { '/etc/logstash/conf.d/input.conf':
    ensure  => 'file',
    content => template('profile/logstash/input.conf.erb'),
    require => Package['logstash'],
    notify  => Service['logstash'],
  }

  file { '/etc/logstash/conf.d/output.conf':
    ensure  => 'file',
    content => template('profile/logstash/output.conf.erb'),
    require => Package['logstash'],
    notify  => Service['logstash'],
  }

  file { '/etc/logstash/conf.d/filter.conf':
    ensure  => 'file',
    content => template('profile/logstash/filter.conf.erb'),
    require => Package['logstash'],
    notify  => Service['logstash'],
  }

  service { 'logstash':
    ensure  => running,
    enable  => true,
    require => [Package['logstash'],
      File['/etc/logstash/conf.d/input.conf'],
      File['/etc/logstash/conf.d/output.conf'],
      File['/etc/logstash/conf.d/filter.conf']
    ],
  }

  file { '/usr/local/bin/es_reopen_closed_indexes.sh':
    ensure => 'file',
    source => 'puppet:///modules/profile/logstash/es_reopen_closed_indexes.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0744'
  }

  include profile::icinga2::objects::logstash_checks

}
