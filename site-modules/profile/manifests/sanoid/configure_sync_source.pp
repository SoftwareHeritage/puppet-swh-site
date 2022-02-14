define profile::sanoid::configure_sync_source(
  String $user,
  String $ssh_key_name,
  String $ssh_key_type,
  String $authorized_key,
) {

  include profile::sanoid::install

  ensure_resource('ssh_authorized_key', $ssh_key_name, {
      ensure => 'present',
      user   => $user,
      type   => $ssh_key_type,
      key    => $authorized_key,
  })
}
