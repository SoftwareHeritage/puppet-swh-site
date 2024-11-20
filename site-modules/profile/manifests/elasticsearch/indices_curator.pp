class profile::elasticsearch::indices_curator {
  ensure_packages (['python3-venv'])

  exec { 'create curator venv':
    command => '/usr/bin/python3 -m venv /opt/curatorVenv',
    creates => '/opt/curatorVenv',
    require => Package['python3-venv'],
  }

  -> exec { 'pip install elasticsearch-curator':
    command => '/opt/curatorVenv/bin/pip install --upgrade elasticsearch-curator',
    # Only run the command if elasticsearch-curator is not installed, or if it's outdated
    unless  => '/bin/sh -c "/opt/curatorVenv/bin/pip list | grep -qF elasticsearch-curator && /opt/curatorVenv/bin/pip list -o | grep -qvF elasticsearch-curator"',
  }
}
