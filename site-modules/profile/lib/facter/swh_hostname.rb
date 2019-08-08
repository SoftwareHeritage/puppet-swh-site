require 'puppet'
require 'socket'

domain_names = [
  ".internal.softwareheritage.org",
  ".internal.staging.swh.network"
]

default_domain_name = domain_names[0]

Facter.add(:swh_hostname) do
  setcode do
    retval = {}
    retval["fqdn"] = Facter.value(:fqdn).to_s

    filtered_domain = domain_names.select { |domain_name|
      retval["fqdn"].end_with?(domain_name)
    }.first

    if filtered_domain
      retval["short"] = retval["fqdn"].chomp(filtered_domain)
      retval["internal_fqdn"] = retval["fqdn"]
    else
      retval["short"] = Socket.gethostname
      retval["internal_fqdn"] = retval["short"] + default_domain_name
    end
    retval
  end
end
