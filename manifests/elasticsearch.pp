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

  class { 'elasticsearch':
    instances => {
      'es-01' => {
        'config' => {
          'cluster.name' => 'clustername',
          'node.name' => 'nodename',
          'network.host' => '127.0.0.1',
          'discovery.zen.ping.unicast.hosts' => [
		'a',
		'b',
		'c',
	  ],
	  # XXX: should depend on cluster size. Always have at least n+1 machines.
          'discovery.zen.minimum_master_nodes' => 2,
	  # Good for archiving: use half of heap memory for indexing operations.
          'indices.memory.index_buffer_size' => '50%',
        },
        datadir => '/srv/elasticsearch',
      },
    },
    manage_repo => false,
    # XXX: how do we remove options ?
    # Ensure we do not keep CMS options ?
    jvm_options => [
      '-Xms15g',
      '-Xmx15g',
      '-XX:+UseG1GC',
    ]
  }
}
