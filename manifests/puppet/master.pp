# Puppet master profile
class profile::puppet::master {
  $puppetmaster = hiera('puppet::master::hostname')

  class { '::puppet':
    server                      => true,
    server_parser               => 'future',
    server_foreman              => false,
    server_environments         => [],
    server_passenger            => true,
    server_storeconfigs_backend => 'active_record',

    runmode                     => 'none',
    pluginsync                  => true,
    puppetmaster                => $puppetmaster,
  }
}
