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

  $users.each |$name, $data| {
    if $data['authorized_keys'] {
      file { "/home/$name/.ssh":
        ensure  => directory,
        owner   => $name,
        mode    => '0600',
        require => User[$name],
      }

      $data['authorized_keys'].each |$nick, $key| {
        ssh_authorized_key { "$name $nick":
          ensure  => 'present',
          user    => $name,
          key     => $key['key'],
          type    => $key['type'],
          require => File["/home/$name/.ssh"],
        }
      }
    }
  }
}
