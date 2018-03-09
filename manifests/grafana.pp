class profile::grafana {
  class {'::grafana':
    install_method => 'repo',
  }
}
