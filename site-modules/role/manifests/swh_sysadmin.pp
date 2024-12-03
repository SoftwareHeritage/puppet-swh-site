class role::swh_sysadmin inherits role::swh_server {
  include profile::prometheus::server

  include profile::prometheus::sql

  include profile::puppet::master
  include profile::cassandra::coordinator

  if $::subnet == 'vagrant' {
    notice("Vagrant environment detected, deactivate let's encrypt and bind_server")
  } else {
    include profile::letsencrypt
    include profile::bind_server::primary
  }

  include profile::icinga2::icingaweb2

  include profile::apache::simple_server
  include ::apache::mod::rewrite

  include profile::annex_web
  include profile::docs_web
  include profile::debian_repository
  include profile::preseeding_vhost
  include profile::bitbucket_archive_web
  include profile::www_static_backup_web

  include profile::weekly_reminder_bot
  include profile::monthly_report_bot

  include profile::swh_web_inbound_email

  include profile::opnsense::monitoring

  include profile::status_io_metrics
}
