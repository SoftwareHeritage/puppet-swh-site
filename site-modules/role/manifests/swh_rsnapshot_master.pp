class role::swh_rsnapshot_master inherits role::swh_base {
  include profile::puppet::agent
  include profile::rsnapshot::master
}
