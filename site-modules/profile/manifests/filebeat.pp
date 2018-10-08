# Filebeat apache log shipper profile

class profile::filebeat {

  # Filebeat official package installation instructions:
  # https://www.elastic.co/guide/en/beats/filebeat/current/setup-repositories.html
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

  package { 'filebeat':
    ensure => '6.3.2',
  }

}
