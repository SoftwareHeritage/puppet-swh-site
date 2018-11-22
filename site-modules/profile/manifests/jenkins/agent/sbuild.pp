class profile::jenkins::agent::sbuild {
  $packages = ['sbuild', 'build-essential', 'devscripts', 'git-buildpackage']

  package {$packages:
    ensure => installed,
  }

  file {'/usr/share/jenkins/debian-scripts':
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
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

  ::sudo::conf { 'jenkins-sbuild':
    ensure   => present,
    content  => 'jenkins  ALL = NOPASSWD: ALL',
    priority => 20,
  }
}
