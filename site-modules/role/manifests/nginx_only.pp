# role for a server only deploying nginx
class role::nginx_only inherits role::swh_base {
  include profile::nginx
}
