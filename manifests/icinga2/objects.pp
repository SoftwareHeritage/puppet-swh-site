# Icinga2 object definitions
class profile::icinga2::objects {
  include profile::icinga2::objects::templates
  include profile::icinga2::objects::common_checks
  include profile::icinga2::objects::static_checks
}
