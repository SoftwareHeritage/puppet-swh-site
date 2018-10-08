class profile::kibana {

  package { 'openjdk-8-jre-headless':
    ensure => 'present',
  }

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

  package { 'kibana':
    ensure => '6.3.2',
  }

  apt::pin { 'kibana':
    packages => 'kibana',
    version => '6.3.2',
    priority => 1001,
  }

  file { '/etc/kibana/kibana.yml':
    ensure => 'file',
    content => template('profile/kibana/kibana.yml.erb'),
  }

}