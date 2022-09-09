# Thanos role
class role::swh_thanos inherits role::swh_base {
  include profile::thanos::query
  include profile::thanos::store
}
