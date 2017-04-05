# Manage the configuration of the systemd journal
class profile::systemd_journal {

  $role = hiera('systemd_journal::role')

  include profile::systemd_journal::apt_config
  include profile::systemd_journal::base_config
}
