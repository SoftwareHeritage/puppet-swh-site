class profile::jenkins::agent::docker {
  include profile::docker

  $jenkins_docker_uid = lookup('jenkins::agent::docker::uid')
  $jenkins_docker_gid = lookup('jenkins::agent::docker::gid')

  group {'jenkins-docker':
    gid    => $jenkins_docker_gid,
    system => true,
  }

  user {'jenkins-docker':
    uid    => $jenkins_docker_uid,
    gid    => $jenkins_docker_gid,
    system => true,
  }

  ::docker::system_user {'jenkins':
    tag => 'reload_jenkins',
  }

  $socket_override = join([
    '[Socket]',
    'ExecStartPost=setfacl -m g:jenkins:rw /run/docker.sock',
    'ExecStartPost=setfacl -m g:jenkins-docker:rw /run/docker.sock',
    '',
  ], "\n")

  ::systemd::dropin_file {"docker-jenkins-access.conf":
    ensure  => 'present',
    unit    => 'docker.socket',
    content => $socket_override,
  }
}
