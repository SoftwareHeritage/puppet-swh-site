node 'louvre.softwareheritage.org' {
  include role::swh_hypervisor_master
}

node 'beaubourg.softwareheritage.org',
     'orsay.softwareheritage.org',
     'hypervisor3.softwareheritage.org'
{
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
  include role::swh_apache_log_archiver
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
  include role::swh_rsnapshot_master
}

node
  'esnode1.internal.softwareheritage.org',
  'esnode2.internal.softwareheritage.org',
  'esnode3.internal.softwareheritage.org'
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

node /^worker\d+\.(internal\.)?softwareheritage\.org$/ {
  include role::swh_worker_inria
}

node /^worker\d+\..*\.azure\.internal\.softwareheritage\.org$/ {
  include role::swh_worker_azure
}

node /^dbreplica(0|1)\.euwest\.azure\.internal\.softwareheritage\.org$/ {
  include role::swh_database
}

node /^ceph-osd\d+\.internal\.softwareheritage\.org$/ {
  include role::swh_ceph_osd
}

node /^ceph-mon\d+\.internal\.softwareheritage\.org$/ {
  include role::swh_ceph_mon
}

node /^ns\d+\.(.*\.azure\.)?internal\.softwareheritage\.org/ {
  include role::swh_nameserver_secondary
}

node 'thyssen.internal.softwareheritage.org' {
  include role::swh_ci_server
}

node /^jenkins-debian\d+\.internal\.softwareheritage\.org$/ {
  include role::swh_ci_agent_debian
}

node 'logstash0.internal.softwareheritage.org' {
  include role::swh_logstash_instance
}

node 'kibana0.internal.softwareheritage.org' {
  include role::swh_kibana_instance
}

node 'munin0.internal.softwareheritage.org' {
  include role::swh_munin_master
}

node
  'giverny.softwareheritage.org',
  'petit-palais.softwareheritage.org',
  'grand-palais.softwareheritage.org',
  'ddouard-desktop.internal.softwareheritage.org' {
  include role::swh_desktop
}

node default {
  include role::swh_base
  include profile::puppet::agent
}
