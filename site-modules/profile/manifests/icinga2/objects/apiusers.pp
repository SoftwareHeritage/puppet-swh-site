# Icinga2 API users
class profile::icinga2::objects::apiusers {
  $apiuser_file = '/etc/icinga2/conf.d/api-users.conf'
  $apiusers = lookup('icinga2::apiusers', Hash, 'deep')

  each($apiusers) |$name, $data| {
    $password = lookup("icinga2::apiusers::${name}::password")
    ::icinga2::object::apiuser {$name:
      password    => $password,
      permissions => $data['permissions'],
      target      => $apiuser_file,
    }
  }
}
