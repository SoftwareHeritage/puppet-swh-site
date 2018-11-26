# Configure the SSH server

class profile::ssh::server {
  $sshd_port = lookup('ssh::port')
  $sshd_permitrootlogin = lookup('ssh::permitrootlogin')

  class { '::ssh::server':
    storeconfigs_enabled => false,
    options              => {
      'PermitRootLogin' => $sshd_permitrootlogin,
      'Port'            => $sshd_port,
    },
  }

  $users = lookup('users', Hash, 'deep')

  each($users) |$name, $data| {
    if $name == 'root' {
      $home = '/root'
    } else {
      $home = "/home/${name}"
    }

    file { "${home}/.ssh":
      ensure  => directory,
      owner   => $name,
      group   => $name,
      mode    => '0600',
      require => [
        User[$name],
        File[$home],
      ],
    }

    if $data['authorized_keys'] {
      each($data['authorized_keys']) |$nick, $key| {
        ssh_authorized_key { "${name} ${nick}":
          ensure  => 'present',
          user    => $name,
          key     => $key['key'],
          type    => $key['type'],
          require => File["${home}/.ssh"],
        }
      }
    }
  }

  each($::ssh) |$algo, $data| {
    @@sshkey {"ssh-${::certname}-${algo}":
      host_aliases => unique(values($::swh_hostname)),
      type         => $algo,
      key          => $data['key'],
    }
  }

  Sshkey <<| |>>
}
