# Process swh-web inbound email

class profile::swh_web_inbound_email {
  $profiles = lookup('swh_web_inbound_email::profiles', Hash)

  $config_dir = '/etc/swh-web-inbound-mail'
  $script = '/usr/local/bin/swh-web-inbound-email.sh'
  $email_dir = '/var/mail/swh-web'

  $file_owner = 'swhwebapp'

  $alias_file = '/etc/postfix/swh-web-inbound-email/aliases'

  file {$config_dir:
    ensure  => directory,
    purge   => true,
    recurse => true,
    owner   => 'root',
    group   => $file_owner,
    mode    => '0750',
  }

  file {$script:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/swh_web_inbound_email/swh-web-inbound-email.sh.erb'),
  }

  file {$email_dir:
    ensure => directory,
    owner  => $file_owner,
    group  => 'mail',
    mode   => '2770',
  }

  $profiles.each |$profile, $config| {
    $profile_email_dir = "${email_dir}/${profile}"
    file {$profile_email_dir:
      ensure => directory,
      owner  => $file_owner,
      group  => 'mail',
      mode   => '2770',

    }

    $config_file = "${config_dir}/${profile}.sh"

    $endpoint = $config['endpoint']
    $shared_key = $config['shared_key']
    file {$config_file:
      ensure  => present,
      owner   => 'root',
      group   => $file_owner,
      mode    => '0640',
      content => template('profile/swh_web_inbound_email/config.sh.erb')
    }

    postfix::virtual {"@${config['email_domain']}":
      destination => [
        "| ${script} ${profile}",
        "${profile_email_dir}/",
      ],
      alias_file  => $alias_file,
      notify      => Exec["postalias ${alias_file}"],
    }
  }
}
