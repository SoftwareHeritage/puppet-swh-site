# Definition of a Borg Backup repository server

define profile::borg::repository (
  String $encryption,
  String $passphrase,
  String $authorized_key,
  String $fqdn            = $title,
){
  include profile::borg::repository_base

  $user = $profile::borg::repository_base::user
  $fullpath = "${profile::borg::repository_base::repository_path}/${fqdn}"
  $borg_authorized_keys = $profile::borg::repository_base::authorized_keys

  exec {"borg init --encryption=${encryption} ${fullpath}":
    user        => $user,
    path        => ['/bin', '/usr/bin'],
    creates     => $fullpath,
    environment => "BORG_PASSPHRASE=${passphrase}",
    require     => Package['borgbackup'],
  }

  ::concat::fragment {"borg-authorized-keys-${fullpath}":
    target  => $borg_authorized_keys,
    order   => '10',
    content => "command=\"borg serve --restrict-to-path ${fullpath}\",restrict ${authorized_key}\n",
    tag     => 'borg-authorized-keys',
  }
}
