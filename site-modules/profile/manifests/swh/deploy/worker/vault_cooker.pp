# Deployment of a vault cooker
class profile::swh::deploy::worker::vault_cooker {
  include ::profile::swh::deploy::base_vault

  $instance_name = 'vault_cooker'

  $config = lookup("swh::deploy::worker::${instance_name}::config", Hash, 'deep')
  if $config['graph'] {
      $extra_packages = [
        "python3-swh.graph.client",
      ]
      package {$extra_packages:
        ensure => 'present',
      }
  }

  ::profile::swh::deploy::worker::instance {$instance_name:
    ensure       => present,
    sentry_name  => 'vault',
    require      => [
      Package[$extra_packages],
      Package[$::profile::swh::deploy::base_vault::packages],
    ],
  }
}
