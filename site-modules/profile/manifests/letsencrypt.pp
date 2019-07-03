# Base configuration for Let's Encrypt

class profile::letsencrypt {
  include ::profile::letsencrypt::apt_config
  include ::profile::letsencrypt::gandi_livedns_hook
  include ::profile::letsencrypt::puppet_export_hook

  class {'letsencrypt':
    config => {
      email  => lookup('letsencrypt::account_email'),
      server => lookup('letsencrypt::server'),
    }
  }

  $certificates = lookup('letsencrypt::certificates', Hash)

  $certificates.each |$key, $settings| {
    $domains = $settings['domains']
    ::letsencrypt::certonly {$key:
      domains              => $domains,
      custom_plugin        => true,
      additional_args      => [
        '--authenticator manual',
        '--preferred-challenges dns',
        '--manual-public-ip-logging-ok',
        "--manual-auth-hook '${::profile::letsencrypt::gandi_livedns_hook::hook_path} auth'",
        "--manual-cleanup-hook '${::profile::letsencrypt::gandi_livedns_hook::hook_path} cleanup'",
        "--deploy-hook '${::profile::letsencrypt::puppet_export_hook::hook_path}'",
      ],
    } -> Profile::Letsencrypt::Certificate <| title == $key |>
  }
}
