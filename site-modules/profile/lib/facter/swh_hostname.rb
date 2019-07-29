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
    domain_names.each do |domain|
      if retval["fqdn"].end_with?(domain)
        retval["short"] = retval["fqdn"].chomp(domain)
        retval["internal_fqdn"] = retval["fqdn"]
        return retval
      end
    end

    # fallback
    retval["short"] = Socket.gethostname
    retval["internal_fqdn"] = retval["short"] + default_domain_name
    retval
  end
end
