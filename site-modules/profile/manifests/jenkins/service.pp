class profile::jenkins::service {
  include profile::jenkins::apt_config
  include profile::jenkins::base

  package {'jenkins':
    ensure  => present,
    require => [
      Apt::Source['jenkins'],
      User['jenkins'],
      Group['jenkins'],
    ],
  }
  -> service {'jenkins':
    ensure => running,
    enable => true,
  }

  Exec <| tag == 'reload_jenkins' |> ~> Service['jenkins']
}
