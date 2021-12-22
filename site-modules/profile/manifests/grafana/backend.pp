# Install the grafana server
# This profile doesn't install any reverse proxy configuration
# to expose the service publicly
class profile::grafana::backend {
  $db_host = lookup('grafana::db::host')
  $db_port = lookup('grafana::db::port')
  $db_username = lookup('grafana::db::username')
  $db_password = lookup('grafana::db::password')

  $config = lookup('grafana::config')

  class {'::grafana':
    install_method          => 'repo',
    provisioning_dashboards => {
        apiVersion => 1,
        providers  => [
          {
            name            => 'default',
            orgId           => 1,
            folder          => '',
            type            => 'file',
            disableDeletion => true,
            options         => {
              path         => '/var/lib/grafana/dashboards',
              puppetsource => 'puppet:///modules/profile/grafana/dashboards',
            },
          },
        ],
      },
      cfg                   => $config + {
        database => {
          type     => 'postgres',
          host     => "${db_host}:${db_port}",
          name     => $db,
          user     => $db_username,
          password => $db_password,
        }
    }
  }

  grafana_plugin {'grafana-piechart-panel':
    ensure => present,
    notify => Service['grafana-server'],
  }

  # this class depends on the reverse proxy availability
  include ::profile::grafana::objects
}
