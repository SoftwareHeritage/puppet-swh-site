# Configure a server to collect journal files sent by remote systems
class profile::systemd_journal::collector {
  $service = 'systemd-journal-remote'

  $config_file = '/etc/systemd/system/journal-remote.conf'

  $keydir = '/etc/ssl/journal-remote'
  $server_key_file = "${keydir}/journal-remote.key"
  $server_certificate_file = "${keydir}/journal-remote.crt"
  $server_ca_file = "${keydir}/journal-remote.ca"

  package {'systemd-journal-remote':
    ensure => installed,
  }

  service {$service:
    ensure  => running,
    enable  => true,
    require => [
      Package['systemd-journal-remote'],
      File[$config_file],
    ],
  }

  file {$keydir:
    ensure  => directory,
    owner   => 'root',
    group   => 'systemd-journal-remote',
    mode    => '0755',
    require => Package['systemd-journal-remote'],
  }

  file {$server_key_file:
    ensure => present,
    owner  => 'root',
    group  => 'systemd-journal-remote',
    mode   => '0640',
    source => $::systemd_journal_puppet_hostprivkey,
  }

  file {$server_certificate_file:
    ensure => present,
    owner  => 'root',
    group  => 'systemd-journal-remote',
    mode   => '0644',
    source => $::systemd_journal_puppet_hostcert,
  }

  file {$server_ca_file:
    ensure => present,
    owner  => 'root',
    group  => 'systemd-journal-remote',
    mode   => '0644',
    source => $::systemd_journal_puppet_localcacert,
  }

  # Uses variables:
  # - $server_key_file
  # - $server_certificate_file
  # - $server_ca_file
  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/systemd_journal/journal-remote.conf.erb'),
    require => [
      Package['systemd-journal-remote'],
      File[$server_key_file, $server_ca_file, $server_certificate_file],
    ],
    notify  => Service[$service]
  }
}
