# Deployment of journal backfill configuration
class profile::swh::deploy::journal::backfill {
  $config_path = lookup('swh::deploy::journal::backfill::config_file')
  $config = lookup('swh::deploy::journal::backfill::config')

  $user = lookup('swh::deploy::journal::backfill::user')
  $group = lookup('swh::deploy::journal::backfill::group')

  file {$config_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n")
  }

}
