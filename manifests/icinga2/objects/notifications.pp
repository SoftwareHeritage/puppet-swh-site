# Icinga2 notifications
class profile::icinga2::objects::notifications {
  $notification_file = '/etc/icinga2/conf.d/notifications.conf'

  $type = 'service'
  $means = 'irc'

  ::icinga2::object::notification {"${means}-notify-all-${type}s":
    import       => ["${means}-${type}-notification"],
    apply        => true,
    apply_target => $type,
    users        => ['root'],
    target       => $notification_file,
  }
}
