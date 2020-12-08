# Deployment of the swh.search.api server
class profile::swh::deploy::search {
  include ::profile::swh::deploy::base_search

  $package = 'python3-swh.search'
  $service = 'gunicorn-swh-search'
  $config_dir = lookup('swh::deploy::base_search::config_directory')
  $config_path = lookup('swh::deploy::search::conf_file')
  $upgrade_flag_path = "${config_dir}/swh-search.upgrade"

  Package[$package]
  ~> exec {'active-initialize':
    command     => "touch ${upgrade_flag_path}",
    path        => '/usr/bin',
    refreshonly => true,
  }
  ~> exec { 'swh-search-initialize':
    command => "swh search --config-file ${config_path} initialize && rm ${upgrade_flag_path}",
    path    => '/usr/bin',
    onlyif  => "test -f ${upgrade_flag_path}",
  }
  ~> Service[$service]

  ::profile::swh::deploy::rpc_server {'search':
    executable => 'swh.search.api.server:make_app_from_configfile()',
  }
}
