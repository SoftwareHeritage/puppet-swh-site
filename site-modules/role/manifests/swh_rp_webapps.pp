# Declare:
# through swh_rp_webapp
# - webapp + associated packages (r/o storage, search)
# - apache reverse proxy (public access to deposit, webapp, ...)
class role::swh_rp_webapps inherits role::swh_rp_webapp {
  include profile::swh::deploy::objstorage_cloud

  # needed for the deposit backend
  include profile::mountpoints
}
