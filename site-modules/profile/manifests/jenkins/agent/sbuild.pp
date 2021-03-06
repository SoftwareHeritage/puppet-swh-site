class profile::jenkins::agent::sbuild {
  include ::profile::haveged

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

  file {'/usr/share/keyrings/extra-repositories':
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  $schroot_overlay = '/srv/softwareheritage/sbuild/overlay'

  exec {"create ${schroot_overlay}":
    creates => $schroot_overlay,
    command => "mkdir -p ${schroot_overlay}",
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
  } -> file {$schroot_overlay:}

  mount {$schroot_overlay:
    ensure  => present,
    dump    => 0,
    pass    => 0,
    device  => 'schroot_overlay',
    fstype  => 'tmpfs',
    options => 'uid=root,gid=root,mode=0750',
    require => File[$schroot_overlay],
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

  $key_uid = "Software Heritage autobuilder (on ${::swh_hostname['short']}) <jenkins@${::swh_hostname['fqdn']}>"
  [$key] = (gpg_key {$key_uid:
    ensure     => present,
    owner      => 'jenkins',
    expire     => '365d',
  })
}
