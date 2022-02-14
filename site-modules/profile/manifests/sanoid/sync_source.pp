# Configure a server to be a source
# of a zfs snapshot synchronization
# mostly configure the ssh key to allow
# the destination server to pull the
# dataset
class profile::sanoid::sync_source {

  ::Profile::Sanoid::Configure_sync_source <<| tag == "${::fqdn}" |>>

}
