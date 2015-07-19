class profile::ssh::server {
  class { '::ssh::server':
    storeconfigs_enabled => false,
    options       => {
      'PermitRootLogin' => 'without-password',
    },
  }
}
