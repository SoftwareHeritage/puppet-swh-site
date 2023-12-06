# Thanos compactor
class role::swh_thanos_compact inherits role::swh_base {
  include profile::thanos::compact
}
