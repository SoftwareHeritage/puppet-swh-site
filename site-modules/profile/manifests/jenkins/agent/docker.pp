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

  file { "/usr/local/bin/clean-docker-images.sh":
    ensure => present,
    source => 'puppet:///modules/profile/jenkins/clean-docker-images.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  exec {'docker swarm init':
    unless => 'docker node inspect self >/dev/null 2>/dev/null',
  }

  $node_labels = [
    'org.softwareheritage.mirror.monitoring',
    'org.softwareheritage.mirror.volumes.elasticsearch',
    'org.softwareheritage.mirror.volumes.objstorage',
    'org.softwareheritage.mirror.volumes.redis',
    'org.softwareheritage.mirror.volumes.scheduler-db',
    'org.softwareheritage.mirror.volumes.storage-db',
    'org.softwareheritage.mirror.volumes.vault-db',
    'org.softwareheritage.mirror.volumes.web-db',
  ]

  $node_labels.each |String $label| {
    exec {"jenkins-agent-docker add label ${label}":
      command => "docker node update \$(docker node inspect self | jq -r .[0].ID) --label-add ${label}=true",
      unless  => "docker node inspect self | jq -r .[0].Spec.Labels.\"${label}\" | grep -qx true",
      require => Exec['docker swarm init'],
    }
  }
}
