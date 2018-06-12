 node 'louvre.softwareheritage.org' {
  include role::swh_hypervisor_master
}

node 'beaubourg.softwareheritage.org', 'orsay.softwareheritage.org' {
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

node 'webapp0.softwareheritage.org' {
  include role::swh_api_azure
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

node
  'esnode1.softwareheritage.org',
  'esnode2.softwareheritage.org',
  'esnode3.softwareheritage.org'
{
  include role::swh_elasticsearch
}

node /^(unibo-test|orangeriedev).(internal.)?softwareheritage.org$/ {
  include role::swh_vault_test
}

node /^(unibo-prod|orangerie).(internal.)?softwareheritage.org$/ {
  include role::swh_vault
}

node /^(uffizi|storage\d+\.[^.]+\.azure).(internal.)?softwareheritage.org$/ {
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

node 'dbreplica0.euwest.azure.internal.softwareheritage.org' {
  include role::swh_database
}

node /^ceph-osd\d+\.internal\.softwareheritage\.org$/ {
  include role::swh_ceph_osd
}

node /^ceph-mon\d+\.internal\.softwareheritage\.org$/ {
  include role::swh_ceph_mon
}

node 'thyssen.internal.softwareheritage.org' {
  include role::swh_ci_server
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
