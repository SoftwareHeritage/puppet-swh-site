class profile::jenkins::apt_config {
  $mirror = lookup('jenkins::apt_config::mirror')
  $keyid =  lookup('jenkins::apt_config::keyid')
  $key =    lookup('jenkins::apt_config::key')

  $keyring_path = '/etc/apt/keyrings/jenkins.asc'

  file { $keyring_path:
    ensure  => present,
    content => $key
  } ~> apt::source {'jenkins':
    location => $mirror,
    release  => 'binary/',
    repos    => undef,
    keyring  => $keyring_path,
    include  => {
      src => false,
      deb => true,
    }
  }
}
