# Icinga2 notifications
class profile::icinga2::objects::notifications {
  $notification_file = '/etc/icinga2/conf.d/notifications.conf'

  $type = 'service'
  $apply_target = "${type[0].upcase}${type[1,-1]}"
  $means = 'irc'

  ::icinga2::object::notification {"${means}-notify-all-${type}s":
    import       => ["${means}-${type}-notification"],
    apply        => true,
    apply_target => $apply_target,
    users        => ['root'],
    target       => $notification_file,
  }
}
