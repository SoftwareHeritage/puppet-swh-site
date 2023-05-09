class role::swh_desktop inherits role::swh_base {
  include profile::desktop
  include profile::devel
  include profile::postgresql
  include profile::zfs
}
