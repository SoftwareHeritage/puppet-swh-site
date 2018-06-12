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

}
