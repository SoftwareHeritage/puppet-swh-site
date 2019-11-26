# Grafanalib-generated dashboards for grafana

class profile::grafana::dashboards {

  file { '/etc/grafana/provisioning/dashboards/10-grafanalib-dashboards.yaml':
    ensure => 'file',
    content => template('profile/grafana/10-grafanalib-dashboards.yaml.erb'),
  }

  package { 'swh-grafanalib-dashboards':
    ensure => 'installed',
  }

}
