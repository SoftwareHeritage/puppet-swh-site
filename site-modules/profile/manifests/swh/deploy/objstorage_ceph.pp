# Deployment of the ceph objstorage

class profile::swh::deploy::objstorage_ceph {

  file {"${profile::swh::deploy::objstorage::conf_directory}/ceph.yml":
    ensure  => absent,
  }
}
