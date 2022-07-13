# Thanos TLS certificate management
class profile::thanos::tls_certificate {
  ::profile::letsencrypt::certificate {'thanos':
    source_cert   => $trusted['certname'],
    privkey_owner => 'prometheus',
  }

  $cert_paths = ::profile::letsencrypt::certificate_paths('thanos')
  $ca_path = '/etc/ssl/certs/ca-certificates.crt'
}
