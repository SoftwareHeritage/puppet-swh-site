# only redis backend
class role::swh_counters_redis inherits role::swh_server {
  include profile::swh::deploy::counters::redis
}
