# Reverse proxy for keycloak

class profile::keycloak::reverse_proxy {
  profile::reverse_proxy {'keycloak':
    extra_apache_opts => {
      proxy_preserve_host => true,
    },
  }
}
