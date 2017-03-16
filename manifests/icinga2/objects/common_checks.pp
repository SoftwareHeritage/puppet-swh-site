# Icinga2 common check definitions
class profile::icinga2::objects::common_checks {
  ::icinga2::object::service {'ping4':
    import        => ['generic-service'],
    apply         => true,
    check_command => 'ping',
    assign        => ['host.address'],
    target        => '/etc/icinga2/zones.d/global-templates/services.conf',
  }

  ::icinga2::object::service {'linux_load':
    import           => ['generic-service'],
    service_name     => 'load',
    apply            => true,
    check_command    => 'load',
    command_endpoint => 'host.name',
    assign           => ['host.vars.os == Linux'],
    ignore           => ['host.vars.noagent'],
    target           => '/etc/icinga2/zones.d/global-templates/services.conf',
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

  ::icinga2::object::service {'linux-ssh':
    import        => ['generic-service'],
    apply         => true,
    check_command => 'ssh',
    assign        => ['host.vars.os == Linux'],
    target        => '/etc/icinga2/zones.d/global-templates/services.conf',
  }
}
