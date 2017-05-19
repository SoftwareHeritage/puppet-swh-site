# Icinga2 object definitions
class profile::icinga2::objects {
  include profile::icinga2::objects::templates
  include profile::icinga2::objects::commands
  include profile::icinga2::objects::users
  include profile::icinga2::objects::notifications
  include profile::icinga2::objects::timeperiods

  include profile::icinga2::objects::common_checks
  include profile::icinga2::objects::static_checks
  include profile::icinga2::objects::agent_checks
  include profile::icinga2::objects::exported_checks
}
