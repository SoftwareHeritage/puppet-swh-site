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
}
