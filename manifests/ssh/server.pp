class profile::ssh::server {
  class { '::ssh':
    storeconfigs_enabled => false,
    server_options       => {
      PermitRootLogin => 'without-password',
    },
  }
}
