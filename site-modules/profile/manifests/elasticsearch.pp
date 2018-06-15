# Elasticsearch cluster node profile

class profile::elasticsearch {

  user { 'elasticsearch':
    ensure => 'present',
    uid    => '114',
    gid    => '119',
    home   => '/home/elasticsearch',
    shell  => '/bin/false',
  }

  file { '/srv/elasticsearch':
    ensure => 'directory',
    owner  => 'elasticsearch',
    mode   => '755',
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
    ensure => 'present',
  }

  service { 'elasticsearch':
    ensure => running,
    enable => true,
  }

}
