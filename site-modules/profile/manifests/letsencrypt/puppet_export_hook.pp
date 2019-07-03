# Certbot deploy hook to copy certificates to a puppet-accessible path

class profile::letsencrypt::puppet_export_hook {
  $hook_path = '/usr/local/bin/letsencrypt_puppet_export'
  file {$hook_path:
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/letsencrypt/letsencrypt_puppet_export.erb'),
  }

  $export_directory = lookup('letsencrypt::certificates::exported_directory')
  file {$export_directory:
    ensure => 'directory',
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0700',
  }
}
