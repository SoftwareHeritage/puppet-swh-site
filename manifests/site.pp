node 'louvre.softwareheritage.org' {
  include role::swh_hypervisor
}

node 'pergamon.softwareheritage.org' {
  include role::swh_sysadmin
}

node 'tate.softwareheritage.org' {
  include role::swh_forge
}

node 'moma.softwareheritage.org' {
  include role::swh_api
}

node 'prado.softwareheritage.org' {
  include role::swh_database
}

node 'uffizi.softwareheritage.org' {
  include role::swh_storage
}

node /worker\d+\.softwareheritage\.org/ {
  include role::swh_worker
}

node default {
  include role::swh_server
}
