require "ipaddr"

excluded_ranges = [
  # RFC 1918
  '10.0.0.0/8',
  '172.16.0.0/12',
  '192.168.0.0/16',
  # Loopback
  '127.0.0.0/8',
  '::1/128',
  # RFC 6598 (CGNAT)
  '100.64.0.0/10',
  # Multicast
  '224.0.0.0/4',
  'ff00::/8',
  # Future use
  '240.0.0.0/4',
  # IPv6 ULA
  'fc00::/7',
  # IPv6 LLA
  'fe80::/10',
].map { |x| IPAddr.new(x) }

Facter.add(:public_ipaddresses) do
  setcode do
    addresses = []
    interfaces = Facter.value(:networking).fetch('interfaces', {})

    interfaces.each do |iface, data|
      [
        data.fetch('bindings', []),
        data.fetch('bindings6', []),
      ].flatten.each do |addr|
        ip = addr['address']
        unless ip.nil?
          addresses.push(ip)
        end
      end
    end

    addresses.uniq.select do |addr|
      ipaddress = IPAddr.new(addr)
      not excluded_ranges.any? { |range| range.include?(ipaddress) }
    end
  end
end
