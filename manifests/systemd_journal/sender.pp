# Configure a server to send its journal to a remote system
class profile::systemd_journal::sender {

  include ::systemd

  $config_file = '/etc/systemd/journal-upload.conf'

  $url = hiera('systemd_journal::upload_url')

  $service = 'systemd-journal-upload'
  $dropin_dir = "/etc/systemd/system/${service}.service.d"
  $unbound_dropin = "${dropin_dir}/unbound.conf"

  $keydir = '/etc/ssl/journal-upload'
  $server_key_file = "${keydir}/journal-upload.key"
  $server_certificate_file = "${keydir}/journal-upload.crt"
  $server_ca_file = "${keydir}/journal-upload.ca"

  package {'systemd-journal-remote':
    ensure => installed,
  }

  service {$service:
    ensure  => running,
    enable  => true,
    require => [
      Package['systemd-journal-remote'],
      File[$unbound_dropin],
      Exec['systemd-daemon-reload'],
    ],
  }

  file {$dropin_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {$unbound_dropin:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Unit]\nAfter=unbound.service\n",
    notify  => Exec['systemd-daemon-reload'],
  }

  file {$keydir:
    ensure  => directory,
    owner   => 'root',
    group   => 'systemd-journal-upload',
    mode    => '0755',
    require => Package['systemd-journal-remote'],
  }

  file {$server_key_file:
    ensure => present,
    owner  => 'root',
    group  => 'systemd-journal-upload',
    mode   => '0640',
    source => $::systemd_journal_puppet_hostprivkey,
  }

  file {$server_certificate_file:
    ensure => present,
    owner  => 'root',
    group  => 'systemd-journal-upload',
    mode   => '0644',
    source => $::systemd_journal_puppet_hostcert,
  }

  file {$server_ca_file:
    ensure => present,
    owner  => 'root',
    group  => 'systemd-journal-upload',
    mode   => '0644',
    source => $::systemd_journal_puppet_localcacert,
  }

  # Uses variables:
  # - $url
  # - $server_key_file
  # - $server_certificate_file
  # - $server_ca_file
  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/systemd_journal/journal-upload.conf.erb'),
    require => [
      Package['systemd-journal-remote'],
      File[$server_key_file, $server_ca_file, $server_certificate_file],
    ],
    notify  => Service[$service]
  }
}
