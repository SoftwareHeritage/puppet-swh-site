# Configure hitch to support a given TLS cert
define profile::hitch::ssl_cert (
  String $ssl_cert_name = $title,
){
  include ::profile::ssl

  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::hitch::domain {$ssl_cert_name:
    key_source    => $ssl_key,
    cert_source   => $ssl_cert,
    cacert_source => $ssl_chain,
  }
}
