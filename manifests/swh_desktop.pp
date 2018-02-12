class role::swh_desktop inherits role::swh_base {
  include profile::puppet::agent
  include profile::desktop
  include profile::devel
  include profile::postgresql
}
