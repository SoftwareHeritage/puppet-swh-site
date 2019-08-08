class profile::logstash {

  package { 'openjdk-8-jre-headless':
    ensure => 'present',
  }

  $keyid =   lookup('elastic::apt_config::keyid')
  $key =     lookup('elastic::apt_config::key')
  $version = sprintf("1:%s-1", lookup('elastic::elk_version'))

  apt::source { 'elastic-6.x':
    location => 'https://artifacts.elastic.co/packages/6.x/apt',
    release  => 'stable',
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  }

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
