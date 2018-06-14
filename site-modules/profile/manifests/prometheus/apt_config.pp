# APT configuration for prometheus
class profile::prometheus::apt_config {
  if $facts['os']['distro']['codename'] == 'stretch' {
    $pinned_packages = [
      'prometheus',
      'prometheus-alertmanager',
      'prometheus-node-exporter',
    ]

    ::apt::pin {'prometheus':
      explanation => 'Pin prometheus to backports',
      codename    => 'stretch-backports',
      packages    => $pinned_packages,
      priority    => 990,
    }

  } else {
    ::apt::pin {'prometheus':
      ensure => absent
    }
  }
}
