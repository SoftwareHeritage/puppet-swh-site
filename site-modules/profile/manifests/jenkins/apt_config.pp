class profile::jenkins::apt_config {
  $mirror = lookup('jenkins::apt_config::mirror')
  $keyid =  lookup('jenkins::apt_config::keyid')
  $key =    lookup('jenkins::apt_config::key')

  apt::source {'jenkins':
    location => $mirror,
    release  => 'binary/',
    repos    => '',
    key      => {
      id      => $keyid,
      content => $key,
    },
    include  => {
      src => false,
      deb => true,
    }
  }
}
