class profile::elasticsearch::indices_curator {
  ensure_packages (['python3-venv'])
  $esnodes = lookup('elasticsearch::hosts')
  $indices = lookup('elasticsearch::curator::indices')
  $retention = lookup('elasticsearch::curator::retention')

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

  file { '/etc/default/curator_config.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/elasticsearch/curator_config.erb'),
  }

  file { '/etc/default/curator_action_delete_indices':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/elasticsearch/curator_action_delete_indices.erb'),
  }
}
