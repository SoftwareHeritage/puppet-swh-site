class profile::jenkins::server {
  include profile::jenkins::apt_config

  package {'jenkins':
    ensure  => present,
    require => Apt::Source['jenkins'],
  }
}
