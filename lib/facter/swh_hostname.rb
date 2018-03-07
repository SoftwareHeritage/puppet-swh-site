require 'puppet'
require 'socket'

domain_name = ".internal.softwareheritage.org"

Facter.add(:swh_hostname) do
  setcode do
    retval = {}
    retval["fqdn"] = Facter.value(:fqdn).to_s
    if retval["fqdn"].end_with?(domain_name)
      retval["short"] = retval["fqdn"].chomp(domain_name)
      retval["internal_fqdn"] = retval["fqdn"]
    else
      retval["short"] = Socket.gethostname
      retval["internal_fqdn"] = retval["short"] + domain_name
    end
    retval
  end
end
