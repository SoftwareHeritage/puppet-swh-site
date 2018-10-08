# Elasticsearch cluster node profile

class profile::elasticsearch {

  user { 'elasticsearch':
    ensure => 'present',
    uid    => '114',
    gid    => '119',
    home   => '/home/elasticsearch',
    shell  => '/bin/false',
  }

  package { 'openjdk-8-jre-headless':
    ensure => 'present',
  }

  # Elasticsearch official package installation instructions:
  # https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html
  $keyid =  lookup('elastic::apt_config::keyid')
  $key =    lookup('elastic::apt_config::key')

  apt::source { 'elastic-6.x':
    location => 'https://artifacts.elastic.co/packages/6.x/apt',
    release  => 'stable',
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  }

  package { 'elasticsearch':
    ensure => '6.3.2',
  }

  apt::pin { 'elasticsearch':
    packages => 'elasticsearch elasticsearch-oss',
    version => '6.3.2',
    priority => 1001,
  }

  # niofs increases I/O performance and node reliability
  file_line { 'elasticsearch niofs':
    ensure => present,
    line   => 'index.store.type: niofs',
    path   => '/etc/elasticsearch/elasticsearch.yml',
  }

  systemd::dropin_file { 'elasticsearch.conf':
    unit   => 'elasticsearch.service',
    content  => template('profile/swh/elasticsearch.conf.erb'),
  }

  service { 'elasticsearch':
    ensure => running,
    enable => true,
  }
}