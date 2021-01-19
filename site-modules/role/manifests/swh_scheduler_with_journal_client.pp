# Install the swh-scheduler stack + the scheduler's journal client
class role::swh_scheduler_with_journal_client inherits role::swh_scheduler {
  include profile::swh::deploy::scheduler::journal_client
}
