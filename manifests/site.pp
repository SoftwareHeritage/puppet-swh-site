 node 'louvre.softwareheritage.org' {
  include role::swh_hypervisor_master
}

node 'beaubourg.softwareheritage.org' {
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

node 'saatchi.internal.softwareheritage.org' {
  include role::swh_scheduler
}

node /^(prado|somerset).(internal.)?softwareheritage.org$/ {
  include role::swh_database
}

node 'banco.softwareheritage.org' {
  include role::swh_backup
}

node /^(unibo-test|orangeriedev).(internal.)?softwareheritage.org$/ {
  include role::swh_vault_test
}

node /^uffizi.(internal.)?softwareheritage.org$/ {
  include role::swh_storage
}

node /^getty.(internal.)?softwareheritage.org$/ {
  include role::swh_eventlog
}

node 'worker08.softwareheritage.org' {
  include role::swh_worker_inria_miracle
}

node /^worker\d+\.(internal\.)?softwareheritage\.org$/ {
  include role::swh_worker_inria
}

node /^worker\d+\..*\.azure\.internal\.softwareheritage\.org$/ {
  include role::swh_worker_azure
}

node
  'giverny.softwareheritage.org',
  'petit-palais.softwareheritage.org',
  'grand-palais.softwareheritage.org'{
  include role::swh_desktop
}

node default {
  include role::swh_server
  include profile::puppet::agent
}
