# Icinga2 users
class profile::icinga2::objects::users {
  $user_file = '/etc/icinga2/conf.d/users.conf'

  ::icinga2::object::user {'root':
    import => ['generic-user'],
    email  => 'root',
    target => $user_file,
  }
}
