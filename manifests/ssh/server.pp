class profile::ssh::server {
  class { '::ssh::server':
    storeconfigs_enabled => false,
    options       => {
      'PermitRootLogin' => 'without-password',
    },
  }

  $users = merge(
    hiera('users::base_users'),
    hiera('users::extra_users')
  )

  each($users) |$name, $data| {
    if $name == 'root' {
      $home = '/root'
    } else {
      $home = "/home/$name"
    }

    if $data['authorized_keys'] {
      file { "$home/.ssh":
        ensure  => directory,
        owner   => $name,
        group   => $name,
        mode    => '0600',
        require => [
          User[$name],
          File["$home"],
        ],
      }

      each($data['authorized_keys']) |$nick, $key| {
        ssh_authorized_key { "$name $nick":
          ensure  => 'present',
          user    => $name,
          key     => $key['key'],
          type    => $key['type'],
          require => File["$home/.ssh"],
        }
      }
    }
  }


}
