class role::swh_forge inherits role::swh_server {
  include profile::network

  include profile::apache::rewrite_domains

  include profile::phabricator
  include profile::mediawiki

  # Reverse proxies
  include profile::jenkins::reverse_proxy
  include profile::keycloak::reverse_proxy
}
