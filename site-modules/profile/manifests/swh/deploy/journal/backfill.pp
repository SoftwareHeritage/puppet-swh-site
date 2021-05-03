# Deployment of journal backfill configuration
class profile::swh::deploy::journal::backfill {
  include profile::swh::deploy::base_storage
  include profile::swh::deploy::journal

  $config_path = lookup('swh::deploy::journal::backfill::config_file')
  $config = lookup('swh::deploy::journal::backfill::config')

  $config_logging_path = lookup('swh::deploy::journal::backfill::config_logging_file')
  $config_logging = lookup('swh::deploy::journal::backfill::config_logging')

  $user = lookup('swh::deploy::journal::backfill::user')
  $group = lookup('swh::deploy::journal::backfill::group')

  file {$config_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n")
  }

  file {$config_logging_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => inline_template("<%= @config_logging.to_yaml %>\n")
  }

}
