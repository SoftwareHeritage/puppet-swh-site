node 'louvre.internal.softwareheritage.org' {
  include role::swh_server
}

node /^(orsay|beaubourg|hypervisor\d+|branly|pompidou|uffizi)\.(internal\.)?softwareheritage\.org$/
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
  include role::swh_rp_webapps
}

node 'webapp1.internal.softwareheritage.org' {
  include role::swh_rp_webapp_with_swh_search
}

node /^search-esnode\d\.internal\.softwareheritage\.org$/ {
  include role::swh_elasticsearch
}

node /^search\d\.internal\.softwareheritage\.org$/ {
  include role::swh_search_with_journal_client
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

node /^(unibo-prod|vangogh).(euwest.azure.)?(internal.)?softwareheritage.org$/ {
  include role::swh_vault
}

node /^saam\.(internal\.)?softwareheritage\.org$/ {
  include role::swh_storage_baremetal
}

node 'storage01.euwest.azure.internal.softwareheritage.org' {
  include role::swh_storage_cloud
}

node 'storage02.euwest.azure.internal.softwareheritage.org' {
  include role::swh_storage_cassandra
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

node 'kelvingrove.internal.softwareheritage.org' {
  include role::swh_idp_primary
}

node 'giverny.softwareheritage.org' {
  include role::swh_desktop
}

node /^db\d\.internal\.staging\.swh\.network$/ {
  include role::swh_database
  include profile::postgresql::server
  include profile::pgbouncer
  include profile::postgresql::client
}

node "bardo.internal.admin.swh.network" {
  include role::swh_hedgedoc
}

node 'scheduler0.internal.staging.swh.network' {
  include role::swh_scheduler
  include profile::postgresql::client
}

node 'gateway.internal.staging.swh.network' {
  include role::swh_gateway
}

node /^storage\d\.internal\.staging\.swh\.network$/ {
  include role::swh_base_storage
  include profile::postgresql::client
  include profile::swh::deploy::journal::backfill
}

node /^worker\d\.internal\.staging\.swh\.network$/ {
  include role::swh_worker_inria
}

node /^search-esnode\d\.internal\.staging\.swh\.network$/ {
  include role::swh_elasticsearch
}

node /^search\d\.internal\.staging\.swh\.network$/ {
  include role::swh_search_with_journal_client
}

node 'webapp.internal.staging.swh.network' {
  include role::swh_webapp
}

node 'deposit.internal.staging.swh.network' {
  include role::swh_deposit
}

node 'vault.internal.staging.swh.network' {
  include role::swh_vault
}

node /^rp\d\.internal\.staging\.swh\.network$/ {
  include role::swh_reverse_proxy
}

node 'journal0.internal.staging.swh.network' {
  include role::swh_journal_allinone
}

# Read-only storage for mirrors
node 'objstorage0.internal.staging.swh.network' {
  include role::swh_remote_objstorage
}

node 'bojimans.internal.softwareheritage.org' {
  include role::swh_netbox
}

node 'clearly-defined.internal.staging.swh.network' {
  include role::swh_db_client
}

node default {
  include role::swh_base
}
