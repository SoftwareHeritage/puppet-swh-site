class role::swh_ci_server inherits role::swh_ci {
  # Restore backups for ci server
  include profile::dar::client
}
