class profile::jenkins::agent::sbuild {
  $packages = ['sbuild', 'build-essential', 'devscripts', 'git-buildpackage']

  package {$packages:
    ensure => installed,
  }

  exec {'add jenkins user to sbuild group':
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    command => 'gpasswd -a jenkins sbuild',
    onlyif  => 'getent passwd jenkins',
    unless  => 'getent group sbuild | cut -d: -f4 | grep -qE \'(^|,)jenkins(,|$)\'',
    require => [
      Package['sbuild'],
      User['jenkins'],
    ],
    tag     => 'restart_jenkins',
  }
}
