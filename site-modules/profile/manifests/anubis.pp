# Install and configure Anubis

class profile::anubis {
  $anubis_version = lookup('anubis::version')
  $anubis_deb_url = lookup('anubis::deb_url')
  $anubis_deb_sha256 = lookup('anubis::deb_sha256')

  $anubis_deb = "/var/cache/anubis_${anubis_version}_${facts['os']['architecture']}.deb"

  file {$anubis_deb:
    ensure         => 'present',
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    source         => $anubis_deb_url,
    checksum_value => $anubis_deb_sha256[$anubis_version][$facts['os']['architecture']],
    checksum       => 'sha256',
  }

  -> package {'anubis':
    ensure => $anubis_version,
    source => $anubis_deb,
    notify => Class['systemd::systemctl::daemon_reload'],
  }

  $anubis_files = ['common-bots.yaml']

  $anubis_files.each |$file| {
    file {"/etc/anubis/${file}":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => "puppet:///modules/profile/anubis/${file}",
      require => Package['anubis'],
    } ~> Service <| tag == "anubis" |>
  }

  $enable_for_varnish = lookup('varnish::enable_anubis')
  if $enable_for_varnish {
    $bind_address = lookup('anubis::listen_host')
    $bind_port = lookup('anubis::listen_port')

    $target_address = lookup('varnish::anubis_backend_listen')
    $target_port = lookup('varnish::anubis_backend_port')

    $metrics_listen_network = lookup('prometheus::anubis_varnish::listen_network')
    $metrics_listen_address = lookup('prometheus::anubis_varnish::listen_address', Optional[String], 'first', undef)
    $actual_metrics_listen_address = pick($metrics_listen_address, ip_for_network($metrics_listen_network))
    $metrics_listen_port = lookup('prometheus::anubis_varnish::listen_port')

    profile::prometheus::export_scrape_config {'anubis_varnish':
      target => "${actual_metrics_listen_address}:${metrics_listen_port}",
    }

    file {'/etc/anubis/varnish.env':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profile/anubis/varnish.env.erb'),
      require => Package['anubis'],
      notify  => Service['anubis@varnish.service'],
    }

    file {'/etc/anubis/varnish.botPolicies.yaml':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/profile/anubis/varnish.botPolicies.yaml',
      require => Package['anubis'],
      notify  => Service['anubis@varnish.service'],
    }

    service {'anubis@varnish.service':
      enable  => true,
      ensure  => running,
      tag     => 'anubis',
      require => [
        File['/etc/anubis/varnish.env', '/etc/anubis/varnish.botPolicies.yaml'],
        Package['anubis'],
      ],
    }
  }
}
