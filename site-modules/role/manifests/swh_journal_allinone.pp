class role::swh_journal_allinone inherits role::swh_journal_orchestrator {
  include profile::kafka::broker
}
