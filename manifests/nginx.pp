# Deployment of nginx as a reverse proxy for Software Heritage RPC servers

class profile::nginx {
  $accept_mutex = lookup('nginx::accept_mutex')
  $package_name = lookup('nginx::package_name')

  $names_hash_bucket_size = lookup('nginx::names_hash_bucket_size')
  $names_hash_max_size = lookup('nginx::names_hash_max_size')
  $worker_processes = lookup('nginx::worker_processes')
  if $worker_processes != 'auto' {
    $actual_worker_processes = $worker_processes + 0
  } else {
    $actual_worker_processes = 'auto'
  }

  class {'::nginx':
    package_name           => $package_name,
    manage_repo            => false,
    accept_mutex           => $accept_mutex,
    names_hash_bucket_size => $names_hash_bucket_size,
    names_hash_max_size    => $names_hash_max_size,
    worker_processes       => $actual_worker_processes,
  }
}
