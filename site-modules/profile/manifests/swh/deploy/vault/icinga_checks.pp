# Install icinga checks for one webapp instance
define profile::swh::deploy::vault::icinga_checks (
  $environment      = $title,
  $storage          = undef,
  $webapp           = undef,
)
{
  # Install vault end-to-end checks
  profile::icinga2::objects::e2e_checks_vault {"End-to-end Vault Test(s) in ${environment}":
    server_vault  => $storage,
    server_webapp => $webapp,
    environment   => $environment,
  }
}
