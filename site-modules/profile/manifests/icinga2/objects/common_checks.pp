# Icinga2 common check definitions
class profile::icinga2::objects::common_checks {
  $service_configuration = lookup('icinga2::service_configuration')

  # Done locally on the master
  ::icinga2::object::service {'ping4':
    import        => ['generic-service'],
    apply         => true,
    check_command => 'ping4',
    assign        => ['host.address'],
    target        => '/etc/icinga2/zones.d/global-templates/services.conf',
  }

  ::icinga2::object::service {'linux-ssh':
    import        => ['generic-service'],
    apply         => true,
    check_command => 'ssh',
    assign        => ['host.vars.os == Linux'],
    target        => '/etc/icinga2/zones.d/global-templates/services.conf',
  }

  # Done remotely on the client: command_endpoint = host.name.

  each($service_configuration['load']) |$name, $vars| {
    if $name == 'default' {
      $assign = 'host.vars.os == Linux'
      $ignore = 'host.vars.noagent || host.vars.load'
    } else {
      $assign = "host.vars.os == Linux && host.vars.load == ${name}"
      $ignore = 'host.vars.noagent'
    }

    ::icinga2::object::service {"linux_load_${name}":
      import           => ['generic-service'],
      service_name     => 'load',
      apply            => true,
      check_command    => 'load',
      command_endpoint => 'host.name',
      assign           => [$assign],
      ignore           => [$ignore],
      target           => '/etc/icinga2/zones.d/global-templates/services.conf',
      vars             => $vars,
    }

  }

  ::icinga2::object::service {'linux_disks':
    import           => ['generic-service'],
    apply            => 'disk_name => config in host.vars.disks',
    check_command    => 'disk',
    command_endpoint => 'host.name',
    vars             => 'vars + config',
    assign           => ['host.vars.os == Linux'],
    ignore           => ['host.vars.noagent'],
    target           => '/etc/icinga2/zones.d/global-templates/services.conf',
  }

  ::icinga2::object::service {'apt':
    import           => ['generic-service'],
    apply            => true,
    check_command    => 'apt',
    command_endpoint => 'host.name',
    check_interval   => '3h',
    vars             => {
      apt_timeout => '120',
      apt_only_critical => 'true',
    },
    assign           => ['host.vars.os == Linux'],
    ignore           => ['host.vars.noagent'],
    target           => '/etc/icinga2/zones.d/global-templates/services.conf',
  }

  ::icinga2::object::service {'journalbeat':
    import           => ['generic-service'],
    apply            => true,
    check_command    => 'check_journal',
    command_endpoint => 'host.name',
    assign           => ['host.vars.os == Linux'],
    ignore           => ['-:"check_journal" !in host.vars.plugins', 'host.vars.noagent'],
    target           => '/etc/icinga2/zones.d/global-templates/services.conf',
  }

  ::icinga2::object::service {'puppet_agent':
    import           => ['generic-service'],
    apply            => true,
    check_command    => 'file_age',
    command_endpoint => 'host.name',
    vars             => {
      file_age_file          => '/var/lib/puppet/state/agent_disabled.lock',
      file_age_warning_time  => '14400', # in seconds, warning after 4h
      file_age_critical_time => '86400', # in seconds, critical after 24h
      file_age_ignoremissing => 'true',
    },
    assign           => ['host.vars.os == Linux'],
    ignore           => ['host.vars.noagent'],
    target           => '/etc/icinga2/zones.d/global-templates/services.conf',
  }
}
