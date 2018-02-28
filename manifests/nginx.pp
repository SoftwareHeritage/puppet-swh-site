# Deployment of nginx as a reverse proxy for Software Heritage RPC servers

class profile::nginx {
  $accept_mutex = lookup('nginx::accept_mutex')
  $package_name = lookup('nginx::package_name')

  class {'::nginx':
    package_name => $package_name,
    manage_repo  => false,
    accept_mutex => $accept_mutex,
  }
}
