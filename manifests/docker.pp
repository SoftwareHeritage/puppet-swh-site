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
}
