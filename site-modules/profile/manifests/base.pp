# Base configuration for Software Heritage servers
class profile::base {
  class { '::ntp':
    servers => lookup('ntp::servers'),
  }

  include profile::smtp

  class { '::locales':
    default_locale => lookup('locales::default_locale'),
    locales        => lookup('locales::installed_locales'),
  }

  $packages = lookup('packages', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  $users = lookup('users', Hash, 'deep')
  $groups = lookup('groups', Hash, 'deep')

  each($groups) |$name, $data| {
    group { $name:
      ensure => 'present',
      gid    => $data['gid'],
    }
  }

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

    if ($data['shell'] == '/usr/bin/zsh') {
      Package['zsh'] -> User[$name]
    }

    if ($data['shell'] == '/usr/bin/fish') {
      Package['fish'] -> User[$name]
    }

    if (has_key($groups, $name)) {
      Group[$name] -> User[$name]
    }

    file { $home:
      ensure  => 'directory',
      mode    => $mode,
      owner   => $name,
      group   => $name,
      require => User[$name],
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

  ::sudo::conf { 'local-deploy':
    ensure   => present,
    content  => '%swhdeploy  ALL = NOPASSWD: /usr/local/sbin/swh-puppet-master-deploy, /usr/local/sbin/swh-puppet-test, /usr/local/sbin/swh-puppet-apply, /usr/bin/apt-get update',
    priority => 20,
  }

  class {'::timezone':
    timezone => lookup('timezone'),
  }

  $bind_autogenerate = lookup('bind::autogenerate')
  $bind_key = lookup('bind::update_key')

  each($bind_autogenerate) |$net, $domain| {
    $ipaddr = ip_for_network($net)

    if $ipaddr {
      $reverse = reverse_ipv4($ipaddr)
      $hostnames = values($::swh_hostname).filter |$hostname| { $hostname[-length($domain),-1] == $domain }

      $hostnames.unique.each |$fqdn| {
        @@resource_record { "${fqdn}/A":
          type    => 'A',
          record  => $fqdn,
          data    => $ipaddr,
          keyfile => "/etc/bind/keys/${bind_key}",
        }

        @@resource_record { "${fqdn}/PTR":
          type    => 'PTR',
          record  => $reverse,
          data    => "${fqdn}.",
          keyfile => "/etc/bind/keys/${bind_key}",
        }
      }
    }
  }
}
