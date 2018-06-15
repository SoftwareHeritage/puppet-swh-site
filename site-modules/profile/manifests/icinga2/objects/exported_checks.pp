# Exported checks on the icinga agents
class profile::icinga2::objects::exported_checks {
  ::Icinga2::Object::Service <<| tag == 'icinga2::exported' |>>
}
