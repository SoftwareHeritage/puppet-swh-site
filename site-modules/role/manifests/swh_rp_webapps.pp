# Declare:
# through swh_rp_webapp
# - webapp + associated packages (r/o storage, search)
# - apache reverse proxy
# - deposit
class role::swh_rp_webapps inherits role::swh_rp_webapp {
  include profile::swh::deploy::deposit
  include profile::swh::deploy::objstorage_cloud
  include profile::swh::deploy::objstorage

  # needed for the deposit backend
  include profile::mountpoints
}
