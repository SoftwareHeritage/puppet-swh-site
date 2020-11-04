class role::swh_reverse_proxy inherits role::swh_server {
  include profile::swh::deploy::reverse_proxy
}
