# doesn't inherit swh_server to avoid backups by default
class role::swh_ci inherits role::swh_base {
  include profile::puppet::agent
  include profile::prometheus::node
}
