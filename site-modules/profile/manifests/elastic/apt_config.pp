# APT configuration for Elastic.co

class profile::elastic::apt_config {
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
}
