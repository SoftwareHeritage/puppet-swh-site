#
class role::swh_azure_billing_report inherits role::swh_base {
  include profile::azure_billing_report

  include profile::apache::simple_server
}
