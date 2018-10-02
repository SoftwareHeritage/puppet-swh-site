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
    ensure => '5.6.12',
  }

  file { '/etc/kibana/kibana.yml':
    ensure => 'file',
    content => template('profile/kibana/kibana.yml.erb'),
  }

}
