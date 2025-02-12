Facter.add('hostcrl') do
  setcode { Puppet[:hostcrl] }
end
