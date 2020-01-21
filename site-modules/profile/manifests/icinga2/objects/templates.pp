# Icinga2 object template definitions
class profile::icinga2::objects::templates {

  $template_file = '/etc/icinga2/conf.d/templates.conf'

  ::icinga2::object::host {'generic-host':
    template           => true,
    max_check_attempts => 3,
    check_interval     => '1m',
    retry_interval     => '30s',
    check_command      => 'hostalive',
    target             => $template_file,
  }

  ::icinga2::object::service {'generic-service':
    template           => true,
    max_check_attempts => 5,
    check_interval     => '1m',
    retry_interval     => '30s',
    target             => $template_file,
  }

  ::icinga2::object::user {'generic-user':
    template => true,
    target   => $template_file,
  }

  ::icinga2::object::notification {'host-notification':
    template => true,
    states   => ['Up', 'Down'],
    types    => [
      'Problem', 'Acknowledgement', 'Recovery', 'Custom', 'FlappingStart',
      'FlappingEnd', 'DowntimeStart', 'DowntimeEnd', 'DowntimeRemoved',
    ],
    period   => '24x7',
    target   => $template_file,
  }

  ::icinga2::object::notification {'service-notification':
    template => true,
    states   => ['OK', 'Warning', 'Critical', 'Unknown' ],
    types    => [
      'Problem', 'Acknowledgement', 'Recovery', 'Custom', 'FlappingStart',
      'FlappingEnd', 'DowntimeStart', 'DowntimeEnd', 'DowntimeRemoved',
    ],
    period   => '24x7',
    target   => $template_file,
  }

  each(['host', 'service']) |$type| {
    each(['irc', 'mail']) |$means| {
      ::icinga2::object::notification {"${means}-${type}-notification":
        template => true,
        import   => ["${type}-notification"],
        command  => "${means}-${type}-notification",
        target   => $template_file,
      }
    }
  }

  ::icinga2::object::service {'generic-service-check-e2e':
    template           => true,
    max_check_attempts => 5,
    check_interval     => '24h',
    retry_interval     => '30s',
    target             => $template_file,
  }
}
