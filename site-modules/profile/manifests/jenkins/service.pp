class profile::jenkins::service {
  include profile::jenkins::apt_config

  package {'jenkins':
    ensure  => present,
    require => Apt::Source['jenkins'],
  }
  -> service {'jenkins':
    ensure => running,
    enable => true,
  }
}
