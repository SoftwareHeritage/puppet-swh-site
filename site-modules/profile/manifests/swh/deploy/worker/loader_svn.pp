# Deployment for swh-loader-svn
class profile::swh::deploy::worker::loader_svn {
  $concurrency = lookup('swh::deploy::worker::loader_svn::concurrency')
  $loglevel = lookup('swh::deploy::worker::loader_svn::loglevel')

  $config_file = '/etc/softwareheritage/loader/svn.yml'
  $config = lookup('swh::deploy::worker::loader_svn::config')

  $packages = ['python3-swh.loader.svn']
  $limit_no_file = lookup('swh::deploy::worker::loader_svn::limit_no_file')
  $private_tmp = lookup('swh::deploy::worker::loader_svn::private_tmp')

  package {$packages:
    ensure => 'latest',
  }

  ::profile::swh::deploy::worker::instance {'loader_svn':
    ensure        => present,
    concurrency   => $concurrency,
    loglevel      => $loglevel,
    limit_no_file => $limit_no_file,
    private_tmp   => $private_tmp,
    require       => [
      Package[$packages],
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
