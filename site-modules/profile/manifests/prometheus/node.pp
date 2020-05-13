# Prometheus configuration for nodes
class profile::prometheus::node {
  include profile::prometheus::base

  $defaults_file = '/etc/default/prometheus-node-exporter'

  package {'prometheus-node-exporter':
    ensure => present,
    notify => Service['prometheus-node-exporter'],
  }

  service {'prometheus-node-exporter':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['prometheus-node-exporter'],
      File[$defaults_file],
    ]
  }

  ::systemd::dropin_file {'prometheus-node-exporter/restart.conf':
    ensure   => present,
    unit     => 'prometheus-node-exporter.service',
    filename => 'restart.conf',
    content  => "[Service]\nRestart=always\nRestartSec=5\n",
  }

  $lookup_defaults_config = lookup('prometheus::node::defaults_config', Hash)
  $listen_network = lookup('prometheus::node::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('prometheus::node::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))
  $listen_port = lookup('prometheus::node::listen_port')
  $target = "${actual_listen_address}:${listen_port}"

  $defaults_config = deep_merge(
    $lookup_defaults_config,
    {
      web => {
        listen_address => $target,
      },
    }
  )

  # Uses $defaults_config
  file {$defaults_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/prometheus/node/prometheus-node-exporter.defaults.erb'),
    require => Package['prometheus-node-exporter'],
    notify  => Service['prometheus-node-exporter'],
  }

  $textfile_directory = lookup('prometheus::node::textfile_directory')
  $scripts = lookup('prometheus::node::scripts', Hash, 'deep')
  $scripts_directory = lookup('prometheus::node::scripts::directory')

  file {$scripts_directory:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    recurse => true,
    purge   => true,
    require => Package['prometheus-node-exporter'],
  }

  each($scripts) |$script, $data| {
    file {"${scripts_directory}/${script}":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template("profile/prometheus/node/scripts/${script}.erb"),
    }
    if $data['mode'] == 'cron' {
      cron {"prometheus-node-exporter-${script}":
        ensure => absent,
        user   => $data['cron']['user'],
      }

      profile::cron::d {"prometheus-node-exporter-${script}":
        target      => 'prometheus',
        user        => $data['cron']['user'],
        command     => "chronic ${scripts_directory}/${script}",
        random_seed => "prometheus-node-exporter-${script}",
        *           => $data['cron']['specification'],
      }
    }
  }

  profile::cron::d {'node-exporter-cleanup':
    target      => 'prometheus',
    user        => 'prometheus',
    command     => "chronic find ${textfile_directory} -name *.prom* -mtime +1 -exec rm {} \\+",
    minute      => 'fqdn_rand',
    hour        => 'fqdn_rand',
  }

  profile::prometheus::export_scrape_config {'node':
    target => $target,
  }
}
