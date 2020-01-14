class profile::logstash {
  include ::profile::elastic::apt_config

  $version = sprintf("1:%s-1", lookup('elastic::elk_version'))

  package { 'logstash':
    ensure => $version,
  }

  apt::pin { 'logstash':
    packages => 'logstash',
    version  => $version,
    priority => 1001,
  }

  file { '/etc/logstash/conf.d/input.conf':
    ensure => 'file',
    content => template('profile/logstash/input.conf.erb'),
  }

  file { '/etc/logstash/conf.d/output.conf':
    ensure => 'file',
    content => template('profile/logstash/output.conf.erb'),
  }

  file { '/etc/logstash/conf.d/filter.conf':
    ensure => 'file',
    content => template('profile/logstash/filter.conf.erb'),
  }

  service { 'logstash':
    ensure => running,
    enable => true,
  }

}
