node 'louvre.internal.softwareheritage.org' {
  include role::swh_server
}

node /^(orsay|beaubourg|hypervisor\d+)\.(internal\.)?softwareheritage\.org$/
{
  include role::swh_hypervisor
}

node 'pergamon.softwareheritage.org' {
  include role::swh_sysadmin
  include profile::export_archive_counters
}

node 'tate.softwareheritage.org' {
  include role::swh_forge
}

node 'moma.softwareheritage.org' {
  include role::swh_api
}

node 'webapp0.softwareheritage.org' {
  include role::swh_base_api
}

node 'saatchi.internal.softwareheritage.org' {
  include role::swh_scheduler
}

node /^(belvedere|somerset).(internal.)?softwareheritage.org$/ {
  include role::swh_database
  include profile::pgbouncer
}

node 'banco.softwareheritage.org' {
  include role::swh_backup
  include role::postgresql_backup
}

node /^esnode\d+.(internal.)?softwareheritage.org$/ {
  include role::swh_elasticsearch
}

node /^kafka\d+\./ {
  include role::swh_kafka_broker
}

node /^cassandra\d+\./ {
  include role::swh_cassandra_node
}

node 'granet.internal.softwareheritage.org' {
  include role::swh_graph_backend
}

node /^(unibo-test).(internal.)?softwareheritage.org$/ {
  include role::swh_vault_test
}

node /^(unibo-prod|vangogh).(euwest.azure.)?(internal.)?softwareheritage.org$/ {
  include role::swh_vault
}

node /^uffizi\.(internal\.)?softwareheritage\.org$/ {
  include role::swh_storage_baremetal
}

node /^storage\d+\.[^.]+\.azure\.internal\.softwareheritage\.org$/ {
  include role::swh_base_storage
}

node /^getty.(internal.)?softwareheritage.org$/ {
  include role::swh_journal_orchestrator
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

node 'riverside.internal.softwareheritage.org' {
  include role::swh_sentry
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

node 'giverny.softwareheritage.org' {
  include role::swh_desktop
}

node 'db0.internal.staging.swh.network' {
  include role::swh_base_database
  include profile::postgresql::server
  include profile::pgbouncer
  include ::profile::devel::postgres
}

node 'scheduler0.internal.staging.swh.network' {
  include role::swh_scheduler
  include ::profile::devel::postgres
}

node 'gateway.internal.staging.swh.network' {
  include role::swh_gateway
}

node 'storage0.internal.staging.swh.network' {
  include role::swh_base_storage
  include ::profile::devel::postgres
}

node /^worker\d\.internal\.staging\.swh\.network$/ {
  include role::swh_worker_inria
}

node 'webapp.internal.staging.swh.network' {
  include role::swh_base_api
  include profile::network
}

node 'deposit.internal.staging.swh.network' {
  include role::swh_deposit
  include profile::postgresql::server
  include profile::pgbouncer
  include ::profile::devel::postgres
}

node 'vault.internal.staging.swh.network' {
  include role::swh_vault
}

node 'journal0.internal.staging.swh.network' {
  include role::swh_journal_allinone
}

node default {
  include role::swh_base
}
