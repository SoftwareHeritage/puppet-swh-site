# Base configuration for Let's Encrypt

class profile::letsencrypt {
  include ::profile::letsencrypt::apt_config
  include ::profile::letsencrypt::gandi_livedns_hook

  class {'letsencrypt':
    config => {
      email  => lookup('letsencrypt::account_email'),
      server => lookup('letsencrypt::server'),
    }
  }

  $certificates = lookup('letsencrypt::certificates', Hash)

  $certificates.each |$key, $settings| {
    $domains = $settings['domains']

    $deploy_hook = pick($settings['deploy_hook'], 'puppet_export')

    include "::profile::letsencrypt::${deploy_hook}_hook"
    $deploy_hook_path = getvar("profile::letsencrypt::${deploy_hook}_hook::hook_path")
    $deploy_hook_extra_opts = getvar("profile::letsencrypt::${deploy_hook}_hook::hook_extra_opts")

    File[$deploy_hook_path]
    -> ::letsencrypt::certonly {$key:
      * => deep_merge({
        domains         => $domains,
        custom_plugin   => true,
        additional_args => [
          '--authenticator manual',
          '--preferred-challenges dns',
          '--manual-public-ip-logging-ok',
          "--manual-auth-hook '${::profile::letsencrypt::gandi_livedns_hook::hook_path} auth'",
          "--manual-cleanup-hook '${::profile::letsencrypt::gandi_livedns_hook::hook_path} cleanup'",
          "--deploy-hook '${deploy_hook_path}'",
        ],
      }, $deploy_hook_extra_opts)
    } -> Profile::Letsencrypt::Certificate <| title == $key |>
  }
}
