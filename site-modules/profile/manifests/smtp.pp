# SMTP configuration

class profile::smtp {

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
}
