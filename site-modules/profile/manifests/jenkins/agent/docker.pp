class profile::jenkins::agent::docker {
  include profile::docker

  ::docker::system_user {'jenkins':
    tag => 'reload_jenkins',
  }
}
