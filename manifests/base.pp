# Base configuration for Software Heritage servers
class profile::base {
  class { '::ntp':
    servers => hiera('ntp::servers'),
  }

  class { '::locales':
    default_locale => hiera('locales::default_locale'),
    locales        => hiera('locales::installed_locales'),
  }

  $packages = union(
    hiera('packages::base_packages'),
    hiera('packages::extra_packages')
  )

  package { $packages:
    ensure => present,
  }

  $users = merge(
    hiera('users::base_users'),
    hiera('users::extra_users')
  )

  each($users) |$name, $data| {
    if $name == 'root' {
      $home = '/root'
      $mode = '0600'
    } else {
      $home = "/home/${name}"
      $mode = '0644'
    }

    user { $name:
      ensure  => 'present',
      uid     => $data['uid'],
      comment => $data['full_name'],
      shell   => $data['shell'],
      groups  => $data['groups'],
      require => Group[$data['groups']],
    }

    file { $home:
      ensure  => 'directory',
      mode    => $mode,
      owner   => $name,
      group   => $name,
      require => User[$name],
    }
  }

  $groups = merge(
    hiera('groups::base_groups'),
    hiera('groups::extra_groups')
  )

  each($groups) |$name, $data| {
    group { $name:
      ensure => 'present',
      gid    => $data['gid'],
    }
  }

  $bind_autogenerate = hiera('bind::autogenerate')
  $bind_key = hiera('bind::update_key')

  each($bind_autogenerate) |$net, $zone| {
    $ipaddr = ip_for_network($net)
    if $ipaddr {
      $reverse = reverse_ipv4($ipaddr)
      $fqdn = "${::hostname}.${zone}"

      @@resource_record { "${::hostname}/${zone}/A":
        type    => 'A',
        record  => $fqdn,
        data    => $ipaddr,
        keyfile => "/etc/bind/keys/${bind_key}",
      }

      @@resource_record { "${::hostname}/${zone}/PTR":
        type    => 'PTR',
        record  => $reverse,
        data    => "${fqdn}.",
        keyfile => "/etc/bind/keys/${bind_key}",
      }
    }
  }
}
