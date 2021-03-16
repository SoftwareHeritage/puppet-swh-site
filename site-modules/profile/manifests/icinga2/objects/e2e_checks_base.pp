# swh's end-to-end checks common behavior
class profile::icinga2::objects::e2e_checks_base {
  $packages = ['python3-swh.icingaplugins']
  package {$packages:
    ensure => present
  }
  $check_file = '/etc/icinga2/conf.d/e2e-checks.conf'
}
