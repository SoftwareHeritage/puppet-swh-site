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

  # SSH key management

  $ssh_known_hosts_dir = '/etc/ssh/puppet_known_hosts'
  $ssh_known_hosts_target = "${ssh_known_hosts_dir}/${::fqdn}.keys"

  $ssh_known_hosts = '/etc/ssh/ssh_known_hosts'

  file {$ssh_known_hosts_dir:
    ensure  => directory,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    purge   => true,
    recurse => true,
    notify  => Exec['update ssh_known_hosts'],
  }

  @@::concat {$ssh_known_hosts_target:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Exec['update ssh_known_hosts'],
    tag    => 'ssh_known_hosts',
  }

  @@::concat::fragment {"ssh_known_hosts-header-${::fqdn}":
    target  => $ssh_known_hosts_target,
    content => "# Known hosts for ${::fqdn}\n",
    order   => '00',
    tag     => 'ssh_known_hosts',
  }

  @@::concat::fragment {"ssh_known_hosts-footer-${::fqdn}":
    target  => $ssh_known_hosts_target,
    content => "# End known hosts for ${::fqdn}\n\n",
    order   => '99',
    tag     => 'ssh_known_hosts',
  }

  exec {'update ssh_known_hosts':
    command     => "cat ${ssh_known_hosts_dir}/* > ${ssh_known_hosts}",
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }

  $ssh_aliases = [
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

  each($::ssh) |$algo, $data| {
    $real_algo = $algo ? {
      'ecdsa' => 'ecdsa-sha2-nistp256',
      default => "ssh-${algo}",
    }

    @@::concat::fragment {"ssh-${::fqdn}-${real_algo}":
      target  => $ssh_known_hosts_target,
      content => inline_template("<%= @ssh_aliases.join(',') %> <%= @real_algo %> <%= @data['key'] %>\n"),
      order   => '10',
      tag     => 'ssh_known_hosts',
    }
  }

  Concat <<| tag == 'ssh_known_hosts' |>> -> Exec['update ssh_known_hosts']
  Concat::Fragment <<| tag == 'ssh_known_hosts' |>> -> Exec['update ssh_known_hosts']
}
