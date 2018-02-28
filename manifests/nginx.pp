# Deployment of nginx as a reverse proxy for Software Heritage RPC servers

class profile::nginx {
  $accept_mutex = lookup('nginx::accept_mutex')
  $package_name = lookup('nginx::package_name')

  $names_hash_bucket_size = lookup('nginx::names_hash_bucket_size')
  $names_hash_max_size = lookup('nginx::names_hash_max_size')

  class {'::nginx':
    package_name           => $package_name,
    manage_repo            => false,
    accept_mutex           => $accept_mutex,
    names_hash_bucket_size => $names_hash_bucket_size,
    names_hash_max_size    => $names_hash_max_size,
  }
}
