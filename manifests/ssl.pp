# Deploy SSL certificates
class profile::ssl {
  $public_dir = '/etc/ssl/certs/softwareheritage'
  $private_dir = '/etc/ssl/private/softwareheritage'

  $ssl_certificates = hiera_hash('ssl')

  $certificate_paths = {}
  $ca_paths = {}
  $private_key_paths = {}

  file {$public_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file {$private_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  each($ssl_certificates) |$domain, $data| {
    $certificate_paths[$domain] = "${public_dir}/${domain}.crt"
    $ca_paths[$domain] = "${public_dir}/${domain}.ca"
    $private_key_paths[$domain] = "${private_dir}/${domain}.key"

    file {$certificate_paths[$domain]:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $data['certificate'],
    }

    file {$ca_paths[$domain]:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $data['ca'],
    }

    file {$private_key_paths[$domain]:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $data['private_key'],
    }
  }
}
