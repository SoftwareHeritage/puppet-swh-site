# Icinga2 object template definitions
class profile::icinga2::objects::templates {
  ::icinga2::object::host {'generic-host':
    template           => true,
    max_check_attempts => 3,
    check_interval     => '1m',
    retry_interval     => '30s',
    check_command      => 'hostalive',
    target             => '/etc/icinga/conf.d/templates.conf',
  }

  ::icinga2::object::service {'generic-service':
    template           => true,
    max_check_attempts => 5,
    check_interval     => '1m',
    retry_interval     => '30s',
    target             => '/etc/icinga/conf.d/templates.conf',
  }

  ::icinga2::object::user {'generic-user':
    template => true,
    target   => '/etc/icinga/conf.d/templates.conf',
  }

  ::icinga2::object::notification {'mail-host-notification':
    template => true,
    command  => 'mail-host-notification',
    states   => ['Up', 'Down'],
    types    => ['Problem', 'Acknowledgement', 'Recovery', 'Custom',
                 'FlappingStart', 'FlappingEnd', 'DowntimeStart', 'DowntimeEnd',
                 'DowntimeRemoved' ],
    period   => '24x7',
    target   => '/etc/icinga/conf.d/templates.conf',
  }

  ::icinga2::object::notification {'mail-service-notification':
    template => true,
    command  => 'mail-service-notification',
    states   => ['Ok', 'Warning', 'Critical', 'Unknown' ],
    types    => ['Problem', 'Acknowledgement', 'Recovery', 'Custom',
                 'FlappingStart', 'FlappingEnd', 'DowntimeStart', 'DowntimeEnd',
                 'DowntimeRemoved' ],
    period   => '24x7',
    target   => '/etc/icinga/conf.d/templates.conf',
  }
}
