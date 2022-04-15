class role::swh_scrubber_checkers inherits role::swh_base {
  # checker(s)
  include profile::swh::deploy::scrubber::checker::postgres
}
