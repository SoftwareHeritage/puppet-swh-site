# Prometheus configuration for nodes
class profile::prometheus::node {
  include profile::prometheus::apt_config

  $defaults_file = '/etc/default/prometheus-node-exporter'

  package {'prometheus-node-exporter':
    ensure => latest,
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
      $cron_spec = profile::cron_rand(
        $data['cron']['specification'],
        "prometheus-node-exporter-${script}"
      )

      cron {"prometheus-node-exporter-${script}":
        ensure  => present,
        user    => $data['cron']['user'],
        command => "chronic ${scripts_directory}/${script}",
        *       => $cron_spec,
      }
    }
  }

  profile::prometheus::export_scrape_config {'node':
    target => $target,
  }
}
