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

node 'banco.softwareheritage.org' {
  include role::swh_backup
}

node 'uffizi.softwareheritage.org' {
  include role::swh_storage
}

node 'getty.softwareheritage.org' {
  include role::swh_eventlog
}

node 'worker08.softwareheritage.org' {
  include role::swh_miracle_worker
}

node /worker\d+\.softwareheritage\.org/ {
  include role::swh_worker
}

node
  'petit-palais.softwareheritage.org',
  'grand-palais.softwareheritage.org'{
  include role::swh_desktop
}

node default {
  include role::swh_server
  include profile::puppet::agent
}
