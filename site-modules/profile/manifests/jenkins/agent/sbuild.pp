class profile::jenkins::agent::sbuild {
  $packages = ['sbuild', 'build-essential', 'devscripts', 'git-buildpackage']

  package {$packages:
    ensure => installed,
  }

  if $::lsbdistcodename == 'stretch' {
    $pinned_packages = [
      'devscripts',
      'git',
      'git-buildpackage',
      'git-man',
      'libsbuild-perl',
      'sbuild',
      'schroot',
    ]
  }
  else {
    $pinned_packages = undef
  }

  if $pinned_packages {
    ::apt::pin {'jenkins-sbuild':
      explanation => 'Pin jenkins to backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'jenkins-sbuild':
      ensure => 'absent',
    }
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
