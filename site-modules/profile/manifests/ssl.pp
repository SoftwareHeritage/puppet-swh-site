# Deploy SSL certificates
class profile::ssl {
  $public_dir = '/etc/ssl/certs/softwareheritage'
  $private_dir = '/etc/ssl/private/softwareheritage'

  $ssl_certificates = lookup('ssl', Hash, 'deep')

  $cert_domains = keys($ssl_certificates)

  # Generate {'foo' => "${public_dir}/foo.crt"} from ['foo']
  $certificate_paths = hash(flatten(zip($cert_domains, prefix(suffix($cert_domains, '.crt'), "${public_dir}/"))))
  $chain_paths = hash(flatten(zip($cert_domains, prefix(suffix($cert_domains, '.chain'), "${public_dir}/"))))
  $private_key_paths = hash(flatten(zip($cert_domains, prefix(suffix($cert_domains, '.key'), "${private_dir}/"))))

  file {$public_dir:
    ensure  => 'directory',
    purge   => true,
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file {$private_dir:
    ensure  => 'directory',
    purge   => true,
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }

  each($ssl_certificates) |$domain, $data| {
    file {$certificate_paths[$domain]:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $data['certificate'],
    }

    file {$chain_paths[$domain]:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $data['ca_bundle'],
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
