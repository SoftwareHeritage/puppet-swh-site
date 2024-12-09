class profile::elasticsearch::indices_curator {
  ensure_packages (['python3-venv'])
  $esnodes = lookup('elasticsearch::hosts')
  $long_lifecycle_indices = lookup('elasticsearch::curator::long_lifecycle_indices')
  $short_lifecycle_indices = lookup('elasticsearch::curator::short_lifecycle_indices')
  $all_indices = $long_lifecycle_indices + $short_lifecycle_indices
  $long_retention = lookup('elasticsearch::curator::long_retention')
  $short_retention = lookup('elasticsearch::curator::short_retention')
  $closing_delay = lookup('elasticsearch::curator::closing_delay')
  $curator_config = lookup('elasticsearch::curator::config')
  $curator_logs = lookup('elasticsearch::curator::logs')
  $actions = {
    'close-indices'  => lookup('elasticsearch::curator::close'),
    'delete-indices' => lookup('elasticsearch::curator::delete'),
  }

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

  $actions.each | $name, $script | {
    file { $script:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => template("profile/elasticsearch/curator-${name}.erb"),
    }
  }

  file { $curator_logs:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/logrotate.d/curator':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/elasticsearch/curator_logrotate.erb'),
  }

  $actions.each | $name, $script | {
    profile::cron::d { "elasticsearch-${name}":
      target  => 'elasticsearch',
      command => "chronic /opt/curatorVenv/bin/curator --config ${curator_config} ${script} --logfile ${curator_logs}/${name}.log",
      user    => 'root',
      minute  => 'fqdn_rand',
      hour    => 'fqdn_rand',
    }
  }
}
