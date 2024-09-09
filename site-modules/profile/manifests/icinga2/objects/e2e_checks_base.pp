# swh's end-to-end checks common behavior
class profile::icinga2::objects::e2e_checks_base {
  ensure_packages (['python3-venv', 'libpq-dev'])

  exec {'create e2e checks venv':
    command => '/usr/bin/python3 -m venv /opt/swh-e2e-checks',
    creates => '/opt/swh-e2e-checks',
    require => Package['python3-venv'],
  }

  -> exec {'pip install e2e checks':
    command  => '/opt/swh-e2e-checks/bin/pip install --upgrade swh.icinga-plugins',
    # Only run the command if swh.icinga-plugins is not installed, or if it's outdated
    unless   => '/bin/sh -c "/opt/swh-e2e-checks/bin/pip list | grep -qF swh.icinga-plugins && /opt/swh-e2e-checks/bin/pip list -o | grep -qvF swh.icinga-plugins"',
    require => Package['libpq-dev'],
  }

  $check_file = '/etc/icinga2/conf.d/e2e-checks.conf'

  User <| title == nagios |> { groups +> "prometheus" }
}
