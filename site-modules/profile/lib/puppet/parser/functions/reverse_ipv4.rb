require "ipaddr"

module Puppet::Parser::Functions

  newfunction(:reverse_ipv4, :type => :rvalue, :doc => <<-EOS
Returns the in-addr.arpa hostname for a given ip address

reverse_ipv4('192.168.1.1') => '1.1.168.192.in-addr.arpa'
    EOS
  ) do |args|

    address = IPAddr.new(args[0])
    return address.reverse()
  end
end
