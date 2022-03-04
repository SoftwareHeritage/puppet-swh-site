# Deployment of nginx as a reverse proxy for Software Heritage RPC servers

class profile::nginx {
  $accept_mutex = lookup('nginx::accept_mutex')
  $package_name = lookup('nginx::package_name')

  $names_hash_bucket_size = lookup('nginx::names_hash_bucket_size')
  $names_hash_max_size = lookup('nginx::names_hash_max_size')
  $worker_processes = lookup('nginx::worker_processes')
  $metrics_port = lookup('nginx::metrics_port')
  $metrics_location = lookup('nginx::metrics_location')

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

  ::nginx::resource::map {'error_status':
    ensure   => present,
    string   => "\$status",
    default  => '1',
    mappings => {
      '~^[23]' => '0',
      '404'    => '0',
    }
  }

  # metrics vhosts
  ::nginx::resource::server {'nginx-metrics':
    ensure         => present,
    listen_ip      => '127.0.0.1',
    listen_port    => $metrics_port,
    listen_options => 'deferred',
    server_name    => [ '127.0.0.1', 'localhost' ],
    format_log     => 'combined',
    locations      => { $metrics_location => { 'stub_status' => true }},
  }

  ::systemd::tmpfile {'nginx.conf':
    content => join([
      '# Managed by puppet (profile::nginx), changes will be lost',
      '',
      'd /run/nginx 0755 root root - -',
      'd /run/nginx/client_body_temp 0700 www-data root - -',
      'd /run/nginx/proxy_temp 0700 www-data root - -',
      '',
    ], "\n")
  }

  include profile::prometheus::nginx
}
