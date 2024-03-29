class profile::jenkins::agent {
  include profile::jenkins::base

  $jenkins_agent_jar_url = lookup('jenkins::agent::jar_url')
  $jenkins_url = lookup('jenkins::backend::url')
  $jenkins_agent_name = lookup('jenkins::agent::name')
  $jenkins_jnlp_token = lookup('jenkins::agent::jnlp::token')

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
  }

  $environment_file = '/etc/default/jenkins-agent'
  file {$environment_file:
    # Contains credentials
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    content => template('profile/jenkins/agent/jenkins-agent.defaults.erb'),
    notify  => Service['jenkins-agent'],
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
