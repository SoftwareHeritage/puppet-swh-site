# Install icinga checks for one deposit instance
define profile::swh::deploy::deposit::icinga_checks (
  # vhost name of the service to check
  $vhost_name       = $title,
  $deposit_server   = $title,
  $vhost_ssl_port   = 443,
  $environment      = undef,
  # The hostname where the services runs (icinga needs it)
  $host_name        = undef,
) {
  $backend_listen_host = lookup('swh::deploy::deposit::backend::listen::host')
  $backend_listen_port = lookup('swh::deploy::deposit::backend::listen::port')

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')
  $icinga_checks_hostname = lookup('icinga2::exported_checks::hostname')

  ::icinga2::object::service {"swh-deposit api (remote on ${vhost_name})":
    service_name  => 'swh-deposit api (remote)',
    import        => ['generic-service'],
    host_name     => $host_name,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_port    => $vhost_ssl_port,
      http_ssl     => true,
      http_uri    => '/',
      http_string => 'The Software Heritage Deposit',
    },
    target        => $icinga_checks_file,
    export_to     => [$icinga_checks_hostname]
  }


  # Install deposit end-to-end checks
  profile::icinga2::objects::e2e_checks_deposit {"End-to-end Deposit Test(s) in ${environment}":
    deposit_server        => "https://${deposit_server}/1",
    deposit_user          => lookup('swh::deploy::deposit::e2e::user'),
    deposit_pass          => lookup('swh::deploy::deposit::e2e::password'),
    deposit_collection    => lookup('swh::deploy::deposit::e2e::collection'),
    deposit_provider_url  => lookup('swh::deploy::deposit::e2e::provider_url'),
    deposit_swh_web_url   => lookup('swh::deploy::deposit::e2e::swh_web_url'),
    deposit_poll_interval => lookup('swh::deploy::deposit::e2e::poll_interval'),
    deposit_archive       => lookup('swh::deploy::deposit::e2e::archive'),
    deposit_metadata      => lookup('swh::deploy::deposit::e2e::metadata'),
    environment           => $environment,
  }

}
