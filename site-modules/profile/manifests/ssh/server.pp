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
    $real_algo = $algo ? {
      'ecdsa' => 'ecdsa-sha2-nistp256',
      default => $algo,
    }

    $aliases = [
      values($::swh_hostname),
      ip_for_network(lookup('internal_network')),
      $::public_ipaddresses,
    ]
    .flatten
    .unique
    .filter |$x| { !!$x } # filter empty values
    .map |$x| {
      case $sshd_port {
        22: {
          case $x {
            /:/: { "[${x}]" } # bracket IPv6 addresses
            default: { $x }
          }
        }
        default: { "[${x}]:${sshd_port}" } # specify non-default ssh port
      }
    }

    @@sshkey {"ssh-${::fqdn}-${real_algo}":
      host_aliases => $aliases,
      type         => $real_algo,
      key          => $data['key'],
    }
  }

  Sshkey <<| |>>
}
