# Base configuration for Software Heritage servers
class profile::base {
  class { '::ntp':
    servers => hiera('ntp::servers'),
  }

  class { '::locales':
    default_locale => hiera('locales::default_locale'),
    locales        => hiera('locales::installed_locales'),
  }

  $packages = hiera_array('packages')

  package { $packages:
    ensure => present,
  }

  $users = hiera_hash('users')

  each($users) |$name, $data| {
    if $name == 'root' {
      $home = '/root'
      $mode = '0600'
    } else {
      $home = "/home/${name}"
      $mode = '0644'
    }

    user { $name:
      ensure   => 'present',
      uid      => $data['uid'],
      comment  => $data['full_name'],
      shell    => $data['shell'],
      groups   => $data['groups'],
      password => $data['password'],
      require  => Group[$data['groups']],
    }

    file { $home:
      ensure  => 'directory',
      mode    => $mode,
      owner   => $name,
      group   => $name,
      require => User[$name],
    }
  }

  $groups = hiera_hash('groups')

  each($groups) |$name, $data| {
    group { $name:
      ensure => 'present',
      gid    => $data['gid'],
    }
  }

  class { '::sudo':
    config_file_replace => false,
    purge               => false,
  }

  ::sudo::conf { 'local-env':
    ensure   => present,
    content  => 'Defaults        env_keep += "GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL"',
    priority => 10,
  }

  $bind_autogenerate = hiera_hash('bind::autogenerate')
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
