# Thanos role
class role::swh_thanos inherits role::swh_server {
  include profile::thanos::query
  include profile::thanos::gateway
}
