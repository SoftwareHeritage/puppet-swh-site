class profile::jenkins::agent {
  include profile::jenkins::base

  $jenkins_agent_jar_url = lookup('jenkins::agent::jar_url')
  $jenkins_url = lookup('jenkins::url')
  $jenkins_agent_name = lookup('jenkins::agent::name')
  $jenkins_jnlp_token = lookup('jenkins::agent::jnlp::token')

  $jnlp_url = "${jenkins_url}/computer/${jenkins_agent_name}/jenkins-agent.jnlp"

  $workdir = '/var/lib/jenkins/agent-workdir'
  file {$workdir:
    mode  => '0700',
    owner => 'jenkins',
    group => 'jenkins',
  }

  $jenkins_agent_jar = '/usr/share/jenkins/agent.jar'
  file {$jenkins_agent_jar:
    source => $jenkins_agent_jar_url,
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => Service['jenkins-agent'],
  }

  $jnlp_secret_file = '/usr/share/jenkins/jnlp-secret'
  file {$jnlp_secret_file:
    content => "${jenkins_jnlp_token}\n",
    mode    => '0600',
    owner   => 'jenkins',
    group   => 'jenkins',
  }

  $environment_file = '/etc/default/jenkins-agent'
  file {$environment_file:
    ensure => absent,
  }

  ::systemd::unit_file {'jenkins-agent.service':
    ensure  => present,
    content => template('profile/jenkins/agent/jenkins-agent.service.erb'),
  } -> service {'jenkins-agent':
    ensure  => running,
    enable  => true,
    require => [
      File[$environment_file],
      File[$workdir],
    ],
  }
}
