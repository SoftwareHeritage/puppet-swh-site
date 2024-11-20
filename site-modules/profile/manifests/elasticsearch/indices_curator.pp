class profile::elasticsearch::indices_curator {
  ensure_packages (['python3-venv'])
  $esnodes = lookup('elasticsearch::hosts')
  $indices = lookup('elasticsearch::curator::indices')
  $retention = lookup('elasticsearch::curator::retention')
  $curator_config = lookup('elasticsearch::curator::config')
  $curator_delete = lookup('elasticsearch::curator::delete')
  $curator_logs = lookup('elasticsearch::curator::logs')

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

  file { $curator_config:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/elasticsearch/curator_config.erb'),
  }

  file { $curator_delete:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/elasticsearch/curator_delete_indices.erb'),
  }

  file { $curator_logs:
    ensure  => 'directory',
    purge   => true,
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/logrotate.d/curator':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/elasticsearch/curator_logrotate.erb'),
  }

  profile::cron::d { 'elasticsearch-delete-indices':
    target  => 'elasticsearch',
    command => "chronic /opt/curatorVenv/bin/curator --config ${curator_config} ${curator_delete} --logfile ${curator_logs}/delete-indices-week-$(date +%W).log",
    user    => 'root',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
  }
}
