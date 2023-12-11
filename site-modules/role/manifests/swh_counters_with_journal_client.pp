# swh counters and its journal client
class role::swh_counters_with_journal_client inherits role::swh_counters {
  include profile::swh::deploy::counters::journal_client
}
