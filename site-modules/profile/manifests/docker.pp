class profile::docker {
  $mirror = lookup('docker::apt_config::mirror')
  $keyid =  lookup('docker::apt_config::keyid')
  $key =    lookup('docker::apt_config::key')

  apt::source {'docker':
    location     => $mirror,
    release      => $facts['os']['distro']['codename'],
    repos        => 'stable',
    architecture => 'amd64',
    key          => {
      id      => $keyid,
      content => $key,
    },
    include      => {
      src => false,
      deb => true,
    }
  }
  -> package {'docker-ce':
    ensure => present,
  }
  -> service {'docker':
    ensure => running,
    enable => true,
  }

  $docker_daemon_config = {
    dns => lookup('dns::forwarders'),
  }

  file {'/etc/docker/daemon.json':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/docker/daemon.json.erb'),
    notify  => Service['docker'],
    require => Package['docker-ce'],
  }

  group {'docker':
    require => Package['docker-ce'],
  }
}
