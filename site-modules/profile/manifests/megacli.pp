# MegaCli proprietary LSI adapters management tool profile

class profile::megacli {

  # From http://hwraid.le-vert.net/wiki/DebianPackages:
  #$keyid =  lookup('hwraid_levert::apt_config::keyid')
  $key =    lookup('hwraid_levert::apt_config::key')

  $keyring_path = '/etc/apt/keyrings/hwraid_levert.asc'

  file { $keyring_path:
    ensure  => present,
    content => $key
  } ~> apt::source { 'hwraid_levert':
    location => 'http://hwraid.le-vert.net/debian',
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
    keyring  => $keyring_path,
  }

  package { 'megacli':
    ensure => 'installed',
  }

}
