class role::swh_journal_orchestrator_with_backfill_config inherits role::swh_journal_orchestrator {
  include profile::swh::deploy::journal::backfill
}
