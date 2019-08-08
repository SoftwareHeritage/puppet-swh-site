# Deployment of the swh.objstorage.api server

class profile::swh::deploy::objstorage {
  $conf_directory = lookup('swh::deploy::objstorage::conf_directory')
  $user = lookup('swh::deploy::objstorage::user')
  $group = lookup('swh::deploy::objstorage::group')
  $swh_packages = ['python3-swh.objstorage']

  package {$swh_packages:
    ensure  => present,
    require => Apt::Source['softwareheritage'],
  }
  Package[$swh_packages] ~> Service['gunicorn-swh-objstorage']

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  ::profile::swh::deploy::rpc_server {'objstorage':
    executable => 'swh.objstorage.api.wsgi',
    worker     => 'async',
  }

  # special configuration for pathslicing
  $objstorage_cfg = lookup('swh::deploy::objstorage::config', Hash)['objstorage']

  if $objstorage_cfg['cls'] == 'pathslicing' {
    $obj_directory = $objstorage_cfg['args']['root']
    file {$obj_directory:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
    }
  }
}
