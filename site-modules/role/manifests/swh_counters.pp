# swh counters
class role::swh_counters inherits role::swh_server {
  include profile::swh::deploy::counters
}
