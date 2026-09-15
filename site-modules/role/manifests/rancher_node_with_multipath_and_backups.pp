class role::rancher_node_with_multipath_and_backups inherits role::rancher_node {
  # multipath stuff
  include profile::megacli
  include profile::multipath

  # Backups repository
  include profile::borg::repository_server
}
