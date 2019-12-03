# Sentry server (no backups)
class role::swh_sentry inherits role::swh_base {
  include profile::puppet::agent
  include profile::sentry
}
