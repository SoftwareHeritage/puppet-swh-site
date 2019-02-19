# Deployment for swh-loader-svn
class profile::swh::deploy::worker::loader_svn {
  $packages = ['python3-swh.loader.svn']
  $limit_no_file = lookup('swh::deploy::worker::loader_svn::limit_no_file')
  $private_tmp = lookup('swh::deploy::worker::loader_svn::private_tmp')

  package {$packages:
    ensure => 'latest',
  }

  ::profile::swh::deploy::worker::instance {'loader_svn':
    ensure        => present,
    limit_no_file => $limit_no_file,
    private_tmp   => $private_tmp,
    require       => [
      Package[$packages],
    ],
  }
}
