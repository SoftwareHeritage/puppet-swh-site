class profile::jenkins::agent::docker {
  include profile::docker

  exec {'add jenkins user to docker group':
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    command => 'gpasswd -a jenkins docker',
    onlyif  => 'getent passwd jenkins',
    unless  => 'getent group docker | cut -d: -f4 | grep -qE \'(^|,)jenkins(,|$)\'',
    require => [
      Package['docker-ce'],
      User['jenkins'],
    ],
    tag     => 'reload_jenkins',
  }
}
