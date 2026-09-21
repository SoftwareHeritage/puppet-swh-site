class role::swh_mediawikis_and_rps inherits role::swh_server {
  include profile::apache::rewrite_domains

  include profile::phabricator
  include profile::mediawiki

  # Reverse proxies
  include profile::jenkins::reverse_proxy
  include profile::keycloak::reverse_proxy

  profile::reverse_proxy {'keycloak-test':
    extra_apache_opts => {
      proxy_preserve_host => true,
    },
    icinga_check_uri  => '/',
  }

}
