# Filebeat apache log shipper profile

class profile::filebeat {
  $config_directory = '/etc/filebeat'
  $config_file = 'filebeat.yml'
  $config_path = "${config_directory}/${config_file}"

  include ::profile::elastic::apt_config

  $default_elk_version = lookup('elastic::elk_version')
  $version = lookup('elastic::beat_version', { default_value => $default_elk_version })

  package { 'filebeat':
    ensure => $version,
  }

  apt::pin { 'filebeat':
    packages => 'filebeat',
    version  => $version,
    priority => 1001,
  }

  service { 'filebeat':
    ensure => running,
    enable => true,
  }

  file { "${config_directory}/inputs.d":
    ensure  => directory,
    purge   => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['filebeat'],
  }

  $filebeat_config = lookup('filebeat::config')

  file { $config_path :
    ensure  => present,
    content => inline_yaml($filebeat_config),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Package['filebeat']],
    notify  => Service['filebeat'],
  }
}
