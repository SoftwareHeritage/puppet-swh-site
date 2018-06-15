# Base configuration for Software Heritage servers
class profile::base {
  class { '::ntp':
    servers => lookup('ntp::servers'),
  }

  $relay_destinations = lookup('smtp::relay_destinations', Array, 'unique').reduce({}) |$ret, $value| {
    $ret + {$value['destination'] => $value['route']}
  }

  $virtual_aliases = lookup('smtp::virtual_aliases', Array, 'unique').reduce({}) |$ret, $value| {
    $ret + {$value['destination'] => $value['alias']}
  }

  class { '::postfix':
    relayhost          => lookup('smtp::relayhost'),
    mydestination      => lookup('smtp::mydestination', Array, 'unique'),
    mynetworks         => lookup('smtp::mynetworks', Array, 'unique'),
    relay_destinations => $relay_destinations,
    virtual_aliases    => $virtual_aliases,
  }

  exec {'newaliases':
    path        => ['/usr/bin', '/usr/sbin'],
    refreshonly => true,
    require     => Package['postfix'],
  }

  $mail_aliases = lookup('smtp::mail_aliases', Array, 'unique')
  each($mail_aliases) |$alias| {
    mailalias {$alias['user']:
      ensure    => present,
      recipient => $alias['aliases'],
      notify    => Exec['newaliases'],
    }
  }

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

  each($bind_autogenerate) |$net| {
    $ipaddr = ip_for_network($net)
    if $ipaddr {
      $reverse = reverse_ipv4($ipaddr)
      $fqdn = $::swh_hostname['internal_fqdn']

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
