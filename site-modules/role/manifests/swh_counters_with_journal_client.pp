# swh counters with redis backend and the counters journal client
class role::swh_counters_with_journal_client inherits role::swh_server {
  include profile::swh::deploy::counters::rpc
  include profile::swh::deploy::counters::redis
  include profile::swh::deploy::counters::journal_client
}
