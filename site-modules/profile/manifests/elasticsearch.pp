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
  $keyid =   lookup('elastic::apt_config::keyid')
  $key =     lookup('elastic::apt_config::key')
  $version = lookup('elastic::elk_version')

  $parsed_version = split($version, '[.]')
  $major_version = $parsed_version[0]

  apt::source { 'elasticsearch':
    location => "https://artifacts.elastic.co/packages/${major_version}.x/apt",
    release  => 'stable',
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  }

  apt::source {'elastic-6.x':
    ensure => absent,
  }

  package { 'elasticsearch':
    ensure => $version,
  }

  apt::pin { 'elasticsearch':
    packages => 'elasticsearch elasticsearch-oss',
    version => $version,
    priority => 1001,
  }

  # hybridfs is the best of both worlds between niofs and mmapfs. It's the ES
  # 7.x default.
  file_line { 'elasticsearch store type':
    ensure => present,
    line   => 'index.store.type: hybridfs',
    match  => '^(#\s*)?index\.store\.type:',
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
