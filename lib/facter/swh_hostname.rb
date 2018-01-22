require 'puppet'
require 'socket'

Facter.add(:swh_hostname) do
	setcode do
		retval = {}
		retval["short"] = Socket.gethostname
		retval["internal_fqdn"] = retval["short"] + ".internal.softwareheritage.org"
		retval["fqdn"] = Facter.value(:fqdn).to_s
		retval
	end
end
