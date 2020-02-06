# Import the letsencrypt certificate generated for this host
class profile::letsencrypt::host_cert {
  ::profile::letsencrypt::certificate {$trusted['certname']:}
}
