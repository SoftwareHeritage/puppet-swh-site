# Retrieve the given certificate from the puppet master

define profile::letsencrypt::certificate (
  String                    $basename         = $title,
  String                    $privkey_owner    = 'root',
  String                    $privkey_group    = 'root',
  Stdlib::Filemode          $privkey_mode     = '0600',
) {
  include ::profile::letsencrypt::certificate_base

  $certs_directory = lookup('letsencrypt::certificates::directory')

  $basedir = "${certs_directory}/${basename}"

  file {$basedir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  ['cert.pem', 'chain.pem', 'fullchain.pem'].each |$filename| {
    file {"${basedir}/${filename}":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///le_certs/${basename}/${filename}",
    }
  }

  ['privkey.pem'].each |$filename| {
    file {"${basedir}/${filename}":
      ensure => present,
      owner  => $privkey_owner,
      group  => $privkey_group,
      mode   => $privkey_mode,
      source => "puppet:///le_certs/${basename}/${filename}",
    }
  }
}
