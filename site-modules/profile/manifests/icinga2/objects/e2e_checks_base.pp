# swh's end-to-end checks common behavior
class profile::icinga2::objects::e2e_checks_base {
  ensure_packages ('python3-venv')

  exec {'create e2e checks venv':
    command => 'python3 -m venv /opt/swh-e2e-checks',
    creates => '/opt/swh-e2e-checks',
  }

  -> exec {'pip install e2e checks':
    command => '/opt/swh-e2e-checks/bin/pip install --upgrade swh.icinga-plugins',
    shell   => true,
    # Only run the command if swh.icinga-plugins is not installed, or if it's outdated
    unless  => [
      '/opt/swh-e2e-checks/bin/pip list | grep -qF swh.icinga-plugins',
      '/opt/swh-e2e-checks/bin/pip list -o | grep -qvF swh.icinga-plugins',
    ],
  }

  $check_file = '/etc/icinga2/conf.d/e2e-checks.conf'

  User <| title == nagios |> { groups +> "prometheus" }
}
