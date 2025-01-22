# MegaCli proprietary LSI adapters management tool profile

class profile::megacli {

  # From http://hwraid.le-vert.net/wiki/DebianPackages:
  $keyid =  lookup('hwraid_levert::apt_config::keyid')
  $key =    lookup('hwraid_levert::apt_config::key')

  $levert_distcodename = if versioncmp($::lsbmajdistrelease, '11') >= 0 { "bullseye" } else { $::lsbdistcodename }

  apt::source { 'hwraid_levert':
    location => 'http://hwraid.le-vert.net/debian',
    release  => $levert_distcodename,
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  }

  package { 'megacli':
    ensure => 'installed',
  }

}
