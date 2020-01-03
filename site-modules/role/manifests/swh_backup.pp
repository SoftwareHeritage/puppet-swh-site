class role::swh_backup inherits role::swh_server {
  include profile::puppet::agent
  include profile::swh::deploy::objstorage
  include profile::swh::deploy::objstorage_ceph
  include profile::megacli
}
