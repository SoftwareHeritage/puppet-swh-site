# Base resources for imported letsencrypt certs

class profile::letsencrypt::certificate_base {
  $certs_directory = lookup('letsencrypt::certificates::directory')

  file {$certs_directory:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
  }
}
