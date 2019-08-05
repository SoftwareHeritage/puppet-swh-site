class role::swh_database inherits role::swh_base_database {
  include profile::munin::plugins::postgresql
  include profile::postgresql
  include profile::megacli
}
