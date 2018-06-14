class profile::desktop::printers {
  $printers = lookup('desktop::printers', Hash, 'deep')
  $default_printer = lookup('desktop::printers::default')
  $cups_usernames = lookup('desktop::printers::cups_usernames', Hash, 'deep')

  $ppd_dir = lookup('desktop::printers::ppd_dir')
  $ppd_file = "${ppd_dir}/MFP.ppd"
  $ppd_auth_filter = "${ppd_dir}/MFP_auth_filter"

  class {'::cups':
    default_printer => $default_printer,
  }

  each($printers) |$printer, $params| {
    printer {$printer:
      ensure      => present,
      uri         => $params['uri'],
      description => $params['description'],
      ppd         => $params['ppd'],
      location    => $params['location'],
      ppd_options => $params['ppd_options'],
      shared      => false,
      require     => File[$params['ppd']],
    }
  }

  Printer[$default_printer] -> Exec['default_printer']

  each ($cups_usernames) |$user, $cups_user| {
    file {"/home/${user}/.cups":
      ensure => directory,
      owner  => $user,
      group  => $user,
      mode   => '0640',
    }

    file {"/home/${user}/.cups/client.conf":
      ensure => present,
      owner  => $user,
      group  => $user,
      mode   => '0640',
    }

    file_line {"cups_username_${user}":
      path  => "/home/${user}/.cups/client.conf",
      line  => "User ${cups_user}",
      match => '^User ',
    }
  }

  file {$ppd_dir:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package['cups'],
  }

  # Template uses $ppd_auth_filter
  file {"${ppd_dir}/MFP_Paris.ppd":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('profile/desktop/printers/MFP_Paris.ppd.erb'),
    require => [
      File[$ppd_dir],
      File[$ppd_auth_filter],
    ],
  }

  file {$ppd_auth_filter:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/profile/desktop/printers/MFP_auth_filter',
    require => [
      File[$ppd_dir],
    ],
  }

  service {'cups-browsed':
    ensure => stopped,
    enable => false,
  }
}
