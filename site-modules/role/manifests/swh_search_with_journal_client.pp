class role::swh_search_with_journal_client inherits role::swh_server {
  include profile::swh::deploy::search
  include profile::swh::deploy::search::journal_client
}
