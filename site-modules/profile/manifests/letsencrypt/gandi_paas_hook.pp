# Push certificates to Gandi PaaS

class profile::letsencrypt::gandi_paas_hook {
  $hook_path = '/usr/local/bin/letsencrypt_gandi_paas'
  $hook_configfile = '/etc/letsencrypt/gandi_paas.yml'
  $hook_config = lookup('letsencrypt::gandi_paas_hook::config', Hash)

  file {$hook_path:
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/letsencrypt/letsencrypt_gandi_paas.erb'),
  }

  file {$hook_configfile:
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => inline_yaml($hook_config),
  }
}
