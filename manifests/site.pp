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

node /^prado.(internal.)?softwareheritage.org$/ {
  include role::swh_database
}

node 'banco.softwareheritage.org' {
  include role::swh_backup
}

node /^uffizi.(internal.)?softwareheritage.org$/ {
  include role::swh_storage
}

node /^getty.(internal.)?softwareheritage.org$/ {
  include role::swh_eventlog
}

node 'worker08.softwareheritage.org' {
  include role::swh_miracle_worker
}

node /^worker\d+\.softwareheritage\.org$/ {
  include role::swh_worker
}

node
  'petit-palais.softwareheritage.org' {
  include role::swh_desktop
}

node
  'grand-palais.softwareheritage.org' {
    include role::swh_desktop
    include profile::swh::deploy::objstorage::log_checker
}
node default {
  include role::swh_server
  include profile::puppet::agent
}
