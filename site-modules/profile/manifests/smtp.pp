# SMTP configuration

class profile::smtp {

  $relay_destinations = lookup('smtp::relay_destinations', Array, 'unique').reduce({}) |$ret, $value| {
    $ret + {$value['destination'] => $value['route']}
  }

  $virtual_aliases = lookup('smtp::virtual_aliases', Array, 'unique').reduce({}) |$ret, $value| {
    $ret + {$value['destination'] => $value['alias']}
  }
  $aliases_files = lookup('smtp::extra_aliases_files', Array)

  class { '::postfix':
    relayhost          => lookup('smtp::relayhost'),
    mydestination      => lookup('smtp::mydestination', Array, 'unique'),
    mynetworks         => lookup('smtp::mynetworks', Array, 'unique'),
    aliases_files      => ['/etc/aliases'] + $aliases_files.map |$a| {"${a['base_directory']}/aliases"},
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

  each ($aliases_files) |$file| {
    $filename = "${file['base_directory']}/aliases"

    exec {"postalias ${filename}":
      path        => ['/usr/bin', '/usr/sbin'],
      refreshonly => true,
      require     => Package['postfix'],
    }

    file {$file['base_directory']:
      ensure => directory,
      mode   => '0755',
      owner  => $file['owner'],
      group  => $file['group'],
    }

    file {$filename:
      ensure => file,
      mode   => '0644',
      owner  => $file['owner'],
      group  => $file['group'],
    }

    each($file['contents']) |$alias| {
      mailalias {"${alias['user']} in ${filename}":
        ensure    => present,
        target    => $filename,
        name      => $alias['user'],
        recipient => $alias['aliases'],
        notify    => Exec["postalias ${filename}"],
        require   => File[$filename],
      }
    }
  }
}
