class profile::kibana {
  include ::profile::elastic::apt_config

  $version = lookup('elastic::elk_version')

  package { 'kibana':
    ensure => $version,
  }

  apt::pin { 'kibana':
    packages => 'kibana',
    version  => $version,
    priority => 1001,
  }

  $kibana_config = deep_merge(lookup('kibana::config'), {
    server => {
      host => ip_for_network(lookup('kibana::listen_network')),
    },
  })

  file { '/etc/kibana/kibana.yml':
    ensure  => 'file',
    owner   => 'root',
    group   => 'kibana',
    mode    => '0640',
    content => inline_yaml($kibana_config),
  }
}
