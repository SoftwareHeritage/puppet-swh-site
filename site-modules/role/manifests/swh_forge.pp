class role::swh_forge inherits role::swh_server {
  include profile::network

  include profile::apache::rewrite_domains

  include profile::phabricator
  include profile::mediawiki
  include profile::jenkins::reverse_proxy
}
