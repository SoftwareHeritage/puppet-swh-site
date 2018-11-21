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
  file {'/usr/share/jenkins':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }
}
