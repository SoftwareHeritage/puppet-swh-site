class profile::jenkins::base {
  group {'jenkins':
    ensure => present,
    system => true,
  }
  -> user {'jenkins':
    ensure => present,
    system => true,
    gid    => 'jenkins',
    home   => '/var/lib/jenkins',
  }
  -> file {'/var/lib/jenkins':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  -> file {'/var/lib/jenkins/.gitconfig':
    ensure => present,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    content => template('profile/jenkins/gitconfig.erb')
  }
  file {'/usr/share/jenkins':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }
}
