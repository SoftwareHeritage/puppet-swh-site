# Icinga2 object command definitions
class profile::icinga2::objects::commands {

  $command_file = '/etc/icinga2/conf.d/commands.conf'

  $hostenv = {
    'NOTIFICATIONTYPE'       => '$notification.type$',
    'HOSTALIAS'              => '$host.display_name$',
    'HOSTADDRESS'            => '$address$',
    'HOSTSTATE'              => '$host.state$',
    'LONGDATETIME'           => '$icinga.long_date_time$',
    'HOSTOUTPUT'             => '$host.output$',
    'NOTIFICATIONAUTHORNAME' => '$notification.author$',
    'NOTIFICATIONCOMMENT'    => '$notification.comment$',
    'HOSTDISPLAYNAME'        => '$host.display_name$',
    'USEREMAIL'              => '$user.email$',
  }

  $serviceenv = $hostenv - 'HOSTOUTPUT' + {
    'SERVICEDESC'            => '$service.name$',
    'SERVICESTATE'           => '$service.state$',
    'SERVICEOUTPUT'          => '$service.output$',
    'SERVICEDISPLAYNAME'     => '$service.display_name$',
  }

  ::icinga2::object::notificationcommand {'mail-host-notification':
    command => ['/etc/icinga2/scripts/mail-host-notification.sh'],
    env     => $hostenv,
    target  => $command_file,
  }

  ::icinga2::object::notificationcommand {'irc-host-notification':
    command => ['/etc/icinga2/scripts/irc-host-notification.sh'],
    env     => $hostenv,
    target  => $command_file,
  }

  ::icinga2::object::notificationcommand {'mail-service-notification':
    command => ['/etc/icinga2/scripts/irc-service-notification.sh'],
    env     => $serviceenv,
    target  => $command_file,
  }

  ::icinga2::object::notificationcommand {'irc-service-notification':
    command => ['/etc/icinga2/scripts/irc-service-notification.sh'],
    env     => $serviceenv,
    target  => $command_file,
  }
}
