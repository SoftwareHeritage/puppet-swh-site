# Deployment of the swh.objstorage.api server

class profile::swh::deploy::objstorage {
  $conf_directory = lookup('swh::deploy::objstorage::conf_directory')
  $group = lookup('swh::deploy::objstorage::group')
  $swh_packages = ['python3-swh.objstorage']

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
  }
  Package[$swh_packages] ~> Service['gunicorn-swh-vault']

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  ::profile::swh::deploy::rpc_server {'objstorage':
    executable => 'swh.objstorage.api.server:make_app_from_configfile()',
    worker     => 'async',
  }
}
