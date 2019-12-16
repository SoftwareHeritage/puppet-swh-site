# Deployment of a vault cooker

class profile::swh::deploy::worker::vault_cooker {
  include ::profile::swh::deploy::base_vault

  ::profile::swh::deploy::worker::instance {'vault_cooker':
    ensure       => present,
    sentry_name  => 'vault',
    require      => [
      Package[$packages],
    ],
  }
}
