# Base configuration for Ceph
class profile::ceph::base {
  $ceph_release = lookup('ceph::release')

  $ceph_fsid = lookup('ceph::fsid')
  $ceph_mon_initial_members = join(lookup('ceph::mon_initial_members'), ',')
  $ceph_mon_host = join(lookup('ceph::mon_host'), ',')

  $ceph_keys = lookup('ceph::keys')

  $ceph_client_keyrings = lookup({
    name       => 'ceph::client_keyrings',
    value_type => Hash,
    merge      => {
      strategy        => 'deep',
      knockout_prefix => '--',
    }
  })

  class {'::ceph::repo':
    release => $ceph_release,
  }

  class {'::ceph':
    fsid                => $ceph_fsid,
    mon_initial_members => $ceph_mon_initial_members,
    mon_host            => $ceph_mon_host,
  }

  each($ceph_client_keyrings) |$file, $data| {
    ::concat {$file:
      ensure => present,
      owner  => $data['owner'],
      group  => $data['group'],
      mode   => $data['mode'],
    }
    each($data['keys']) |$name| {
      $secret = $ceph_keys[$name]['secret']
      ::concat::fragment {"${file}/client.${name}":
        target  => $file,
        content => "[client.${name}]\n\tkey = ${secret}\n",
      }
    }
  }
}
