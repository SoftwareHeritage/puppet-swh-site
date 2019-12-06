class role::swh_database inherits role::swh_base_database {
  include profile::postgresql
  include profile::megacli
}
