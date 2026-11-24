# MegaCli proprietary LSI adapters management tool profile

class profile::megacli {

  # From http://hwraid.le-vert.net/wiki/DebianPackages:
  #$keyid =  lookup('hwraid_levert::apt_config::keyid')
  $key =    lookup('hwraid_levert::apt_config::key')

  # Migrate old debian .list file and related key
  # Drop old filename
  $old_keyring_path = '/etc/apt/keyrings/megacli.asc'
  file {$old_keyring_path:
    ensure => absent,
  }
  $old_source_list_path = '/etc/apt/sources.list.d/hwraid_levert.list'
  file {$old_source_list_path:
    ensure => absent,
  }

  $keyring_path = '/etc/apt/keyrings/hwraid_levert.asc'
  file { $keyring_path:
    ensure  => present,
    content => $key,
    require => File[$old_keyring_path, $old_source_list_path],
  } ~> apt::source { 'hwraid_levert':
    source_format => 'sources',
    location => 'http://hwraid.le-vert.net/debian',
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
    keyring  => $keyring_path,
  }

  package { 'megacli':
    ensure => 'installed',
  }

}
