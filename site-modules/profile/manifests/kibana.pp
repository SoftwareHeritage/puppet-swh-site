class profile::kibana {
  include ::profile::elastic::apt_config

  $version = lookup('elastic::elk_version')

  package { 'kibana':
    ensure => $version,
  }

  apt::pin { 'kibana':
    packages => 'kibana',
    version => $version,
    priority => 1001,
  }

  file { '/etc/kibana/kibana.yml':
    ensure => 'file',
    content => template('profile/kibana/kibana.yml.erb'),
  }

}
