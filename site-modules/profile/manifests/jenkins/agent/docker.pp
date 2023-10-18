class profile::jenkins::agent::docker {
  include profile::docker

  ::docker::system_user {'jenkins':
    tag => 'reload_jenkins',
  }

  ::systemd::dropin_file {"docker-jenkins-access.conf":
    ensure  => 'present',
    unit    => 'docker.socket',
    content => "[Socket]\nExecStartPost=setfacl -m g:jenkins:rw /run/docker.sock\n",
  }
}
