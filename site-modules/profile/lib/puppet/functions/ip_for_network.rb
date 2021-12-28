require "ipaddr"

Puppet::Functions.create_function(:ip_for_network) do
  dispatch :get_ip do
    param 'String', :range
  end

  def get_ip(range)
    addresses_in_range = []
    ip_addresses = []
    interfaces = []

    range = IPAddr.new(range)
    scope = closure_scope
    interfaces = scope['facts']['networking']['interfaces']
    interfaces.each do |name, data|
      bindings = data['bindings']
      unless bindings.nil?
        bindings.each do |binding_|
          ip = binding_['address']
          unless ip.nil?
            ip_addresses.push(ip)
          end
        end
      end
    end

    ip_addresses.each do |string_address|
      ip_address = IPAddr.new(string_address)
      if range.include?(ip_address)
        addresses_in_range.push(string_address)
      end
    end

    # TODO don't be a dork dork with the return
    # handle multiple values!
    return addresses_in_range.first
  end
end
