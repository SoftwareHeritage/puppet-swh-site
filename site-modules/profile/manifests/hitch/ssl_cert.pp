# Configure hitch to support a given TLS cert
define profile::hitch::ssl_cert (
  String $ssl_cert_name = $title,
){
  ::profile::letsencrypt::certificate {$ssl_cert_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($ssl_cert_name)

  ::hitch::domain {$ssl_cert_name:
    cert_source   => $cert_paths['cert'],
    cacert_source => $cert_paths['chain'],
    key_source    => $cert_paths['privkey'],
  }
}
