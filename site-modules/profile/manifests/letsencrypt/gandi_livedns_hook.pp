class profile::letsencrypt::gandi_livedns_hook {
  $hook_path = '/usr/local/bin/letsencrypt_gandi_livedns'
  $hook_configfile = '/etc/letsencrypt/gandi_livedns.yml'
  $hook_config = lookup('letsencrypt::gandi_livedns_hook::config', Hash)

  file {$hook_path:
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/letsencrypt/letsencrypt_gandi_livedns.erb'),
  }

  file {$hook_configfile:
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => inline_yaml($hook_config),
  }
}
