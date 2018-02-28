# Deployment of nginx as a reverse proxy for Software Heritage RPC servers

class profile::nginx {
  $accept_mutex = hiera('nginx::accept_mutex')
  $package_name = hiera('nginx::package_name')

  class {'::nginx':
    package_name => $package_name,
    manage_repo  => false,
    accept_mutex => $accept_mutex,
  }
}
